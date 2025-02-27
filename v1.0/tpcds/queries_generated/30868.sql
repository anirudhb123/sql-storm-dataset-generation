
WITH RECURSIVE sales_summary AS (
    SELECT
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM
        store_sales
    GROUP BY
        ss_store_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS gender_sales_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
shipping_mode AS (
    SELECT
        COUNT(wr_return_quantity) AS return_count,
        sm.sm_type
    FROM 
        web_returns wr
    JOIN 
        ship_mode sm ON wr.wr_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_type
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.total_web_sales,
    s.total_sales AS store_sales,
    sm.return_count,
    CASE 
        WHEN cs.gender_sales_rank <= 10 THEN 'Top Performer'
        ELSE 'Regular'
    END AS performance_category
FROM 
    customer_summary cs
JOIN 
    sales_summary s ON cs.total_web_sales > 10000
LEFT JOIN 
    shipping_mode sm ON sm.return_count > 100
WHERE 
    cs.total_orders IS NOT NULL
    AND cs.cd_marital_status = 'M'
ORDER BY 
    cs.total_web_sales DESC, s.total_sales ASC;
