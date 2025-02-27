
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
inventory_check AS (
    SELECT 
        i.i_item_sk,
        i.i_current_price,
        COALESCE(inv.inv_quantity_on_hand, 0) AS available_stock
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk AND inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_dep_count > 0 THEN 'Family'
            ELSE 'Single' 
        END AS family_status,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS row_num
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    c.c_customer_sk,
    c.c_gender,
    ci.family_status,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    SUM(ws.ws_sales_price) AS total_spent,
    COALESCE(i.available_stock, 0) AS available_stock,
    CASE 
        WHEN SUM(ws.ws_sales_price) > 1000 THEN 'Valuable Customer'
        ELSE 'Regular Customer' 
    END AS customer_type,
    DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS customer_rank
FROM 
    customer_info ci
JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    inventory_check i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ws.ws_sales_price IS NOT NULL
GROUP BY 
    c.c_customer_sk, c.c_gender, ci.family_status
HAVING 
    SUM(ws.ws_sales_price) > 0 AND 
    COUNT(DISTINCT ws.ws_order_number) > 1
ORDER BY 
    customer_rank, total_spent DESC;
