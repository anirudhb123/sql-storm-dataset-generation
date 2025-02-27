
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss.s_store_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rn
    FROM 
        store_sales ss
    WHERE
        ss.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ss.s_store_sk
),
top_stores AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        ss.total_sales,
        ss.total_transactions
    FROM 
        store s
    JOIN 
        sales_summary ss ON s.s_store_sk = ss.s_store_sk
    WHERE 
        ss.rn <= 10
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(ws.ws_order_number) AS total_web_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT 
    ts.s_store_id,
    ts.s_store_name,
    ts.total_sales,
    ts.total_transactions,
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    COALESCE(cd.total_web_orders, 0) AS total_web_orders
FROM 
    top_stores ts
LEFT JOIN 
    customer_data cd ON cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
ORDER BY 
    ts.total_sales DESC, cd.c_customer_sk
LIMIT 50;
