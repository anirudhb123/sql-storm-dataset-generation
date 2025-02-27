
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk AS date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
item_info AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        COALESCE(i_brand, 'Unknown') AS brand_name
    FROM 
        item
),
customer_summary AS (
    SELECT 
        c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales
    LEFT JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    GROUP BY 
        c_customer_sk
),
max_sales AS (
    SELECT 
        date_sk,
        MAX(total_sales) AS max_sales
    FROM 
        sales_summary
    GROUP BY 
        date_sk
)
SELECT 
    i.i_item_desc,
    i.brand_name,
    S.total_quantity,
    S.total_sales,
    C.total_orders,
    C.total_spent,
    MAX(M.max_sales) OVER() AS overall_max_sales,
    CASE 
        WHEN C.total_spent IS NULL THEN 'No orders'
        WHEN C.total_spent > 1000 THEN 'High spender'
        ELSE 'Regular spender'
    END AS spending_category
FROM 
    sales_summary S
JOIN 
    item_info i ON S.ws_item_sk = i.i_item_sk
JOIN 
    customer_summary C ON C.c_customer_sk = S.ws_bill_customer_sk
LEFT JOIN 
    max_sales M ON S.date_sk = M.date_sk
ORDER BY 
    S.total_sales DESC, 
    S.total_quantity DESC;
