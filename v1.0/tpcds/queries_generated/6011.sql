
WITH CustomerStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd.cd_dep_count) AS total_dependents,
        AVG(cd.cd_credit_rating) AS avg_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
SalesStats AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_paid) AS total_net_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year
),
StoreStats AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_quantity) AS total_store_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_revenue
    FROM 
        store_sales ss
    JOIN 
        warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.cd_gender,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.total_dependents,
    ss.d_year,
    ss.total_sales_quantity,
    ss.total_net_sales,
    st.w_warehouse_id,
    st.total_store_sales,
    st.total_store_revenue
FROM 
    CustomerStats cs
JOIN 
    SalesStats ss ON cs.customer_count > 1000
JOIN 
    StoreStats st ON st.total_store_revenue > 50000
ORDER BY 
    cs.customer_count DESC, ss.d_year DESC, st.total_store_sales DESC;
