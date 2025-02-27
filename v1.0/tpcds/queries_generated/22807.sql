
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws.ws_item_sk
), sales_summary AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        COALESCE(rank.total_quantity, 0) AS total_quantity,
        COALESCE(rank.total_sales, 0) AS total_sales,
        rank.sales_rank
    FROM
        item
    LEFT JOIN ranked_sales rank ON item.i_item_sk = rank.ws_item_sk
), store_inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    WHERE 
        inv.inv_warehouse_sk IN (SELECT w.w_warehouse_sk FROM warehouse w WHERE w.w_country = 'USA')
    GROUP BY 
        inv.inv_item_sk
), customer_preferences AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT CASE WHEN cd.cd_gender = 'F' THEN c.c_customer_id END) AS female_customers,
        COUNT(DISTINCT CASE WHEN cd.cd_marital_status = 'M' THEN c.c_customer_id END) AS married_customers,
        COUNT(DISTINCT c.c_customer_id) AS total_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    s.item_id,
    s.item_desc,
    s.total_quantity,
    s.total_sales,
    inv.total_inventory,
    cp.female_customers,
    cp.married_customers,
    cp.total_customers
FROM 
    sales_summary s
LEFT JOIN 
    store_inventory inv ON s.i_item_sk = inv.inv_item_sk
LEFT JOIN 
    customer_preferences cp ON s.i_item_sk = cp.c_customer_id
WHERE 
    (s.total_sales > 1000 OR s.total_quantity < 10)
    AND COALESCE(inv.total_inventory, 0) >= (
        SELECT 
            AVG(total_inventory) FROM store_inventory
    )
ORDER BY 
    s.total_sales DESC
LIMIT 100;

