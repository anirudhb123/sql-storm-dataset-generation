
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_market_id,
        s_manager,
        1 AS level
    FROM 
        store
    WHERE 
        s_store_sk IS NOT NULL

    UNION ALL

    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.s_market_id,
        sh.s_manager,
        level + 1
    FROM 
        store sh
    INNER JOIN 
        sales_hierarchy shier ON sh.s_market_id = shier.s_market_id
    WHERE 
        sh.s_store_sk <> shier.s_store_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_purchases,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
sales_summary AS (
    SELECT 
        h.s_store_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        sales_hierarchy h
        INNER JOIN web_sales ws ON h.s_store_sk = ws.ws_warehouse_sk
    GROUP BY 
        h.s_store_name
),
top_sales AS (
    SELECT 
        s.s_store_name,
        s.total_sales,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        sales_summary s
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(ts.total_sales, 0) AS store_total_sales,
    COALESCE(ts.sales_rank, 'N/A') AS sales_rank
FROM 
    customer_info ci
LEFT JOIN 
    top_sales ts ON ci.c_customer_sk = ts.total_orders 
ORDER BY 
    ci.c_last_name, ci.c_first_name
FETCH FIRST 100 ROWS ONLY;
