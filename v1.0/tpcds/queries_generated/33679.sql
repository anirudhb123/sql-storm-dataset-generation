
WITH RECURSIVE sales_trends AS (
    SELECT 
        d.d_year,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ss_sales_price) DESC) AS trend_rank
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
store_performance AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    s.s_store_name,
    sp.total_store_sales,
    st.total_sales,
    st.d_year,
    CASE 
        WHEN st.trend_rank <= 5 THEN 'Top Trend'
        ELSE 'Regular Trend'
    END AS sales_trend_indicator
FROM 
    customer_info ci
JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    store_performance sp ON ws.ws_store_sk = sp.s_store_sk
JOIN 
    sales_trends st ON ws.ws_sold_date_sk = st.d_year
WHERE 
    (ci.cd_marital_status = 'M' OR ci.cd_marital_status IS NULL)
    AND (sp.total_store_sales > (SELECT AVG(total_store_sales) FROM store_performance) OR sp.total_store_sales IS NULL)
ORDER BY 
    st.d_year DESC, sp.total_store_sales DESC;
