
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_gender,
        SUM(ws.ws_sales_price) OVER (PARTITION BY c.c_customer_sk) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
        AND cd.cd_purchase_estimate IS NOT NULL
        AND (cd.cd_gender IS NOT NULL OR cd.cd_marital_status IS NULL)
), high_spenders AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.total_spent,
        CASE 
            WHEN rc.total_spent > 1000 THEN 'VIP'
            ELSE 'Regular'
        END AS customer_type
    FROM 
        ranked_customers rc
    WHERE 
        rc.rank_by_gender <= 10
), top_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        SUM(ws.ws_quantity) > 100
), inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        COALESCE(ts.total_quantity, 0) AS total_sold
    FROM 
        inventory inv
    LEFT JOIN 
        top_sales ts ON inv.inv_item_sk = ts.ws_item_sk
), final_summary AS (
    SELECT 
        hs.c_customer_sk,
        hs.c_first_name,
        hs.c_last_name,
        hs.customer_type,
        is.inv_item_sk,
        is.inv_quantity_on_hand,
        is.total_sold,
        COALESCE(is.inv_quantity_on_hand - is.total_sold, is.inv_quantity_on_hand) AS available_stock
    FROM 
        high_spenders hs
    JOIN 
        inventory_status is ON hs.total_spent > 500
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.customer_type,
    fs.inv_item_sk,
    fs.available_stock,
    CASE 
        WHEN fs.available_stock < 10 THEN 'Low Stock'
        WHEN fs.available_stock BETWEEN 10 AND 50 THEN 'Moderate Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM 
    final_summary fs
WHERE 
    fs.available_stock IS NOT NULL
ORDER BY 
    fs.total_spent DESC, fs.customer_type, fs.available_stock;
