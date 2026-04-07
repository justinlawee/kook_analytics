import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd
import altair as alt

st.set_page_config(layout="wide")

session = get_active_session()

@st.cache_data(ttl=600)
def run_query(sql):
    return session.sql(sql).to_pandas()

st.title("KOOK Analytics Dashboard")
st.caption("Reef-safe essentials that care for both body and sea")

orders = run_query("SELECT * FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS")
orders["CREATED_AT"] = pd.to_datetime(orders["CREATED_AT"])
orders["ORDER_MONTH"] = pd.to_datetime(orders["ORDER_MONTH"])

with st.sidebar:
    st.header("Filters")
    min_date = orders["CREATED_AT"].min().date()
    max_date = orders["CREATED_AT"].max().date()
    date_range = st.date_input("Date Range", value=(min_date, max_date), min_value=min_date, max_value=max_date)

    channels = ["All"] + sorted(orders["SALES_CHANNEL"].dropna().unique().tolist())
    channel = st.selectbox("Sales Channel", channels)

    states = ["All"] + sorted(orders[orders["BILLING_STATE"].notna() & (orders["BILLING_STATE"] != "")]["BILLING_STATE"].unique().tolist())
    state = st.selectbox("State", states)

filtered = orders.copy()
if len(date_range) == 2:
    filtered = filtered[(filtered["CREATED_AT"].dt.date >= date_range[0]) & (filtered["CREATED_AT"].dt.date <= date_range[1])]
if channel != "All":
    filtered = filtered[filtered["SALES_CHANNEL"] == channel]
if state != "All":
    filtered = filtered[filtered["BILLING_STATE"] == state]

tab1, tab2, tab3, tab4, tab5 = st.tabs(["Overview", "Products", "Customers", "Channels & Geo", "Promos & Growth"])

with tab1:
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Total Revenue", f"${filtered['TOTAL_AMOUNT'].sum():,.2f}")
    c2.metric("Orders", f"{len(filtered):,}")
    c3.metric("Avg Order Value", f"${filtered['TOTAL_AMOUNT'].mean():,.2f}" if len(filtered) > 0 else "$0")
    c4.metric("Unique Customers", f"{filtered['CUSTOMER_EMAIL'].nunique():,}")

    c5, c6, c7, c8 = st.columns(4)
    c5.metric("Net Revenue", f"${filtered['NET_REVENUE'].sum():,.2f}")
    c6.metric("Total Discounts", f"${filtered['DISCOUNT_AMOUNT'].sum():,.2f}")
    c7.metric("Total Refunds", f"${filtered['REFUNDED_AMOUNT'].sum():,.2f}")
    refund_rate = 100.0 * filtered["IS_REFUNDED"].sum() / len(filtered) if len(filtered) > 0 else 0
    c8.metric("Refund Rate", f"{refund_rate:.1f}%")

    monthly = filtered.groupby("ORDER_MONTH").agg(
        revenue=("TOTAL_AMOUNT", "sum"),
        orders=("ORDER_ID", "count")
    ).reset_index()

    chart = alt.Chart(monthly).mark_bar(color="#4c78a8").encode(
        x=alt.X("ORDER_MONTH:T", title="Month"),
        y=alt.Y("revenue:Q", title="Revenue ($)")
    ).properties(title="Monthly Revenue", height=350)

    line = alt.Chart(monthly).mark_line(color="#e45756", strokeWidth=2, point=True).encode(
        x="ORDER_MONTH:T",
        y=alt.Y("orders:Q", title="Orders", axis=alt.Axis(titleColor="#e45756"))
    )

    st.altair_chart(
        alt.layer(chart, line).resolve_scale(y="independent"),
        use_container_width=True
    )

with tab2:
    items = run_query("SELECT * FROM KOOK_DATA.DBT_MODELS.FCT_ORDER_ITEMS")
    items["CREATED_AT"] = pd.to_datetime(items["CREATED_AT"])
    items["ORDER_MONTH"] = pd.to_datetime(items["ORDER_MONTH"])
    fi = items.copy()
    if len(date_range) == 2:
        fi = fi[(fi["CREATED_AT"].dt.date >= date_range[0]) & (fi["CREATED_AT"].dt.date <= date_range[1])]
    if channel != "All":
        fi = fi[fi["SALES_CHANNEL"] == channel]
    if state != "All":
        fi = fi[fi["BILLING_STATE"] == state]

    product_rev = fi.groupby("PRODUCT_NAME").agg(
        revenue=("LINE_ITEM_REVENUE", "sum"),
        units=("LINE_ITEM_QUANTITY", "sum"),
        orders=("ORDER_ID", "nunique")
    ).reset_index().sort_values("revenue", ascending=False)

    st.subheader("Product Performance")
    product_chart = alt.Chart(product_rev.head(10)).mark_bar(color="#4c78a8").encode(
        x=alt.X("revenue:Q", title="Revenue ($)"),
        y=alt.Y("PRODUCT_NAME:N", sort="-x", title="")
    ).properties(height=350)
    st.altair_chart(product_chart, use_container_width=True)
    st.dataframe(product_rev, use_container_width=True)

    st.subheader("Product Attach Rate (Top Pairs)")
    pairs = run_query("""
        WITH op AS (SELECT DISTINCT order_id, product_name FROM KOOK_DATA.DBT_MODELS.FCT_ORDER_ITEMS WHERE product_name IS NOT NULL),
        p AS (SELECT a.product_name AS product_a, b.product_name AS product_b, COUNT(DISTINCT a.order_id) AS together
              FROM op a JOIN op b ON a.order_id = b.order_id AND a.product_name < b.product_name GROUP BY 1,2)
        SELECT product_a, product_b, together FROM p ORDER BY together DESC LIMIT 10
    """)
    st.dataframe(pairs, use_container_width=True)

with tab3:
    customers = run_query("SELECT * FROM KOOK_DATA.DBT_MODELS.DIM_CUSTOMERS")

    st.subheader("Customer Segments")
    seg = customers.groupby("CUSTOMER_SEGMENT").agg(
        count=("CUSTOMER_EMAIL", "count"),
        revenue=("LIFETIME_REVENUE", "sum"),
        avg_ltv=("LIFETIME_REVENUE", "mean")
    ).reset_index().sort_values("revenue", ascending=False)

    seg_chart = alt.Chart(seg).mark_bar().encode(
        x=alt.X("CUSTOMER_SEGMENT:N", sort="-y", title=""),
        y=alt.Y("count:Q", title="Customers"),
        color=alt.Color("CUSTOMER_SEGMENT:N", legend=None)
    ).properties(height=300)
    st.altair_chart(seg_chart, use_container_width=True)
    st.dataframe(seg.rename(columns={"count": "customers", "revenue": "total_revenue", "avg_ltv": "avg_ltv"}), use_container_width=True)

    st.subheader("Cohort Retention")
    cohort = run_query("""
        WITH fo AS (SELECT customer_email, DATE_TRUNC('MONTH', MIN(created_at)) AS cohort_month FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS WHERE customer_email IS NOT NULL AND customer_email != '' GROUP BY 1),
        om AS (SELECT DISTINCT customer_email, DATE_TRUNC('MONTH', created_at) AS order_month FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS WHERE customer_email IS NOT NULL AND customer_email != '')
        SELECT f.cohort_month, COUNT(DISTINCT f.customer_email) AS cohort_size,
            COUNT(DISTINCT CASE WHEN DATEDIFF('MONTH', f.cohort_month, om.order_month) = 1 THEN om.customer_email END) AS month_1,
            COUNT(DISTINCT CASE WHEN DATEDIFF('MONTH', f.cohort_month, om.order_month) = 2 THEN om.customer_email END) AS month_2,
            COUNT(DISTINCT CASE WHEN DATEDIFF('MONTH', f.cohort_month, om.order_month) = 3 THEN om.customer_email END) AS month_3,
            COUNT(DISTINCT CASE WHEN DATEDIFF('MONTH', f.cohort_month, om.order_month) = 6 THEN om.customer_email END) AS month_6
        FROM fo f LEFT JOIN om ON f.customer_email = om.customer_email GROUP BY 1 ORDER BY 1
    """)
    cohort["COHORT_MONTH"] = pd.to_datetime(cohort["COHORT_MONTH"]).dt.strftime("%Y-%m")
    for col in ["MONTH_1", "MONTH_2", "MONTH_3", "MONTH_6"]:
        cohort[col + "_PCT"] = (100 * cohort[col] / cohort["COHORT_SIZE"]).round(1)
    st.dataframe(cohort, use_container_width=True)

    st.subheader("Top 15 Customers")
    top = customers.sort_values("LIFETIME_REVENUE", ascending=False).head(15)[
        ["CUSTOMER_EMAIL", "CUSTOMER_NAME", "CUSTOMER_SEGMENT", "LIFETIME_ORDERS", "LIFETIME_REVENUE", "AVG_ORDER_VALUE"]
    ]
    st.dataframe(top, use_container_width=True)

with tab4:
    st.subheader("Revenue by Channel")
    ch = filtered.groupby("SALES_CHANNEL").agg(
        revenue=("TOTAL_AMOUNT", "sum"),
        orders=("ORDER_ID", "count"),
        aov=("TOTAL_AMOUNT", "mean")
    ).reset_index().sort_values("revenue", ascending=False)
    ch = ch[ch["SALES_CHANNEL"].notna() & (ch["SALES_CHANNEL"] != "")]

    ch_chart = alt.Chart(ch).mark_bar().encode(
        x=alt.X("revenue:Q", title="Revenue ($)"),
        y=alt.Y("SALES_CHANNEL:N", sort="-x", title=""),
        color=alt.Color("SALES_CHANNEL:N", legend=None)
    ).properties(height=250)
    st.altair_chart(ch_chart, use_container_width=True)

    st.subheader("Amazon vs Web")
    amz_web = filtered[filtered["SALES_CHANNEL"].isin(["web", "amazon"])].groupby("SALES_CHANNEL").agg(
        revenue=("TOTAL_AMOUNT", "sum"),
        orders=("ORDER_ID", "count"),
        avg_order_value=("TOTAL_AMOUNT", "mean"),
        unique_customers=("CUSTOMER_EMAIL", "nunique"),
        discount_usage_pct=("HAS_DISCOUNT", "mean")
    ).reset_index()
    amz_web["discount_usage_pct"] = (amz_web["discount_usage_pct"] * 100).round(1)
    st.dataframe(amz_web, use_container_width=True)

    st.subheader("Revenue by State")
    geo = filtered[filtered["BILLING_STATE"].notna() & (filtered["BILLING_STATE"] != "")].groupby("BILLING_STATE").agg(
        revenue=("TOTAL_AMOUNT", "sum"),
        orders=("ORDER_ID", "count")
    ).reset_index().sort_values("revenue", ascending=False).head(15)

    geo_chart = alt.Chart(geo).mark_bar(color="#4c78a8").encode(
        x=alt.X("revenue:Q", title="Revenue ($)"),
        y=alt.Y("BILLING_STATE:N", sort="-x", title="")
    ).properties(height=400)
    st.altair_chart(geo_chart, use_container_width=True)

with tab5:
    st.subheader("Discount Code Performance")
    promos = filtered[filtered["HAS_DISCOUNT"] == True].groupby("DISCOUNT_CODE").agg(
        orders=("ORDER_ID", "count"),
        revenue=("TOTAL_AMOUNT", "sum"),
        discount_given=("DISCOUNT_AMOUNT", "sum"),
        aov=("TOTAL_AMOUNT", "mean")
    ).reset_index().sort_values("revenue", ascending=False)
    st.dataframe(promos, use_container_width=True)

    st.subheader("Influencer / Discount Code LTV")
    inf_ltv = run_query("""
        WITH foc AS (
            SELECT customer_email, discount_code FROM (
                SELECT customer_email, discount_code, ROW_NUMBER() OVER (PARTITION BY customer_email ORDER BY created_at) AS rn
                FROM KOOK_DATA.DBT_MODELS.FCT_ORDERS WHERE customer_email IS NOT NULL AND customer_email != ''
            ) WHERE rn = 1 AND discount_code IS NOT NULL AND discount_code != ''
        )
        SELECT fc.discount_code, COUNT(DISTINCT fc.customer_email) AS customers,
            COUNT(DISTINCT CASE WHEN dc.lifetime_orders > 1 THEN fc.customer_email END) AS repeat_customers,
            ROUND(100.0 * COUNT(DISTINCT CASE WHEN dc.lifetime_orders > 1 THEN fc.customer_email END) / NULLIF(COUNT(DISTINCT fc.customer_email), 0), 1) AS repeat_rate_pct,
            ROUND(AVG(dc.lifetime_revenue), 2) AS avg_ltv
        FROM foc fc JOIN KOOK_DATA.DBT_MODELS.DIM_CUSTOMERS dc ON fc.customer_email = dc.customer_email
        GROUP BY 1 HAVING COUNT(DISTINCT fc.customer_email) >= 2 ORDER BY avg_ltv DESC
    """)
    st.dataframe(inf_ltv, use_container_width=True)

    st.subheader("Monthly Growth Rate")
    growth = monthly.copy().sort_values("ORDER_MONTH")
    growth["prev_revenue"] = growth["revenue"].shift(1)
    growth["growth_pct"] = ((growth["revenue"] - growth["prev_revenue"]) / growth["prev_revenue"] * 100).round(1)

    growth_chart = alt.Chart(growth.dropna(subset=["growth_pct"])).mark_bar().encode(
        x=alt.X("ORDER_MONTH:T", title="Month"),
        y=alt.Y("growth_pct:Q", title="MoM Growth (%)"),
        color=alt.condition(
            alt.datum.growth_pct > 0,
            alt.value("#4c78a8"),
            alt.value("#e45756")
        )
    ).properties(height=300)
    st.altair_chart(growth_chart, use_container_width=True)
