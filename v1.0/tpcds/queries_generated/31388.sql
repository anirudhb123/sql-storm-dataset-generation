
WITH RECURSIVE sales_history AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_ship_date_sk,
        ws_ship_customer_sk,
        ws_quantity,
        ws_ext_sales_price,
        1 AS level
    FROM 
        web_sales 
    WHERE 
        ws_ship_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    UNION ALL
    SELECT 
        c.cs_item_sk,
        c.cs_order_number,
        c.cs_ship_date_sk,
        c.cs_ship_customer_sk,
        c.cs_quantity,
        c.cs_ext_sales_price,
        level + 1
    FROM 
        catalog_sales c
    INNER JOIN sales_history sh ON c.cs_item_sk = sh.ws_item_sk
    WHERE 
        sh.level < 3
),
item_summary AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(sh.ws_quantity) AS total_quantity,
        SUM(sh.ws_ext_sales_price) AS total_sales
    FROM 
        sales_history sh
    JOIN 
        item i ON sh.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id, i.i_product_name
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(is.total_sales), 0) AS total_sales,
        COALESCE(MAX(cd.cd_marital_status), 'Unknown') AS marital_status,
        COUNT(DISTINCT i.i_item_id) AS unique_items_purchased
    FROM 
        customer c
    LEFT JOIN 
        item_summary is ON c.c_customer_sk = is.total_quantity
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    cs.c_customer_sk, 
    cs.c_first_name, 
    cs.c_last_name, 
    cs.total_sales, 
    cs.marital_status,
    CUME_DIST() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
    CASE 
        WHEN cs.total_sales > 1000 THEN 'High Value'
        WHEN cs.total_sales IS NULL OR cs.total_sales = 0 THEN 'No Purchases'
        ELSE 'Low/Medium Value'
    END AS customer_value_category
FROM 
    customer_summary cs
WHERE 
    cs.total_sales > 0
ORDER BY 
    cs.total_sales DESC
LIMIT 50;
