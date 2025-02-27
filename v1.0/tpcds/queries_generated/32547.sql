
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) as total_quantity,
        SUM(ws.ws_ext_sales_price) as total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY SUM(ws.ws_quantity) DESC) as item_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk
),
top_sales AS (
    SELECT 
        ss.ws_order_number, 
        ss.ws_item_sk, 
        ss.total_quantity, 
        ss.total_sales
    FROM 
        sales_summary ss
    WHERE 
        ss.item_rank = 1
)
SELECT 
    t.ws_order_number,
    COUNT(DISTINCT t.ws_item_sk) as items_count,
    SUM(t.total_sales) as total_sales_amount,
    AVG(t.total_quantity) as avg_quantity_per_item,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS top_products
FROM 
    top_sales t
JOIN 
    item i ON t.ws_item_sk = i.i_item_sk
GROUP BY 
    t.ws_order_number
ORDER BY 
    total_sales_amount DESC
LIMIT 10;

-- Additional analysis for customer demographics related to the top sales
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(ws.ws_ext_sales_price) AS total_sales_amount
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
ORDER BY 
    total_sales_amount DESC;
