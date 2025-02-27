
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT ws.ws_order_number) AS web_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY 
        c.c_customer_sk
),
demographic_summary AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(cs.c_customer_sk) AS num_customers,
        AVG(cs.total_store_sales) AS avg_store_sales,
        AVG(cs.total_web_sales) AS avg_web_sales
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer_sales cs ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
sales_trends AS (
    SELECT 
        dd.d_year,
        SUM(cs.total_store_sales) AS yearly_store_sales,
        SUM(cs.total_web_sales) AS yearly_web_sales
    FROM 
        date_dim dd
    JOIN 
        store_sales ss ON dd.d_date_sk = ss.ss_sold_date_sk
    JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    JOIN 
        customer_sales cs ON ss.ss_customer_sk = cs.c_customer_sk
    GROUP BY 
        dd.d_year
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    ds.num_customers,
    ds.avg_store_sales,
    ds.avg_web_sales,
    st.yearly_store_sales,
    st.yearly_web_sales
FROM 
    demographic_summary ds
JOIN 
    sales_trends st ON ds.cd_demo_sk = (SELECT hd.hd_demo_sk FROM household_demographics hd WHERE hd.hd_income_band_sk = 1 LIMIT 1)
ORDER BY 
    ds.cd_gender, ds.cd_marital_status;
