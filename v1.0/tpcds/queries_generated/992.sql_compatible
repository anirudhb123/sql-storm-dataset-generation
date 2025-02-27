
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
customer_details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cb.ib_lower_bound,
        cb.ib_upper_bound
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band cb ON hd.hd_income_band_sk = cb.ib_income_band_sk
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_date
),
sales_average AS (
    SELECT 
        AVG(total_web_sales) AS avg_web_sales,
        AVG(total_store_sales) AS avg_store_sales
    FROM 
        daily_sales
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.ib_lower_bound,
    cd.ib_upper_bound,
    cs.total_web_sales,
    cs.total_store_sales,
    cs.web_order_count,
    cs.store_order_count,
    sa.avg_web_sales,
    sa.avg_store_sales
FROM 
    customer_sales cs
JOIN 
    customer_details cd ON cs.c_customer_id = cd.c_customer_id
CROSS JOIN 
    sales_average sa
WHERE 
    (cs.total_web_sales > sa.avg_web_sales OR cs.total_store_sales > sa.avg_store_sales)
    AND cd.cd_gender IS NOT NULL
ORDER BY 
    cs.total_web_sales DESC, cs.total_store_sales DESC;
