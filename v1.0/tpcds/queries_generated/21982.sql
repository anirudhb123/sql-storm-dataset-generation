
WITH customer_rank AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
), 
inventory_status AS (
    SELECT 
        inv.inv_item_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM 
        inventory inv
    WHERE 
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv.inv_item_sk
),
store_sales_summary AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_store_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(cs.total_sold, 0) AS web_total_sales,
    COALESCE(ss.total_store_sales, 0) AS store_sales,
    COALESCE(is.total_on_hand, 0) AS inventory_on_hand,
    (COALESCE(cs.total_sold, 0) + COALESCE(ss.total_store_sales, 0)) AS total_combined_sales,
    ROW_NUMBER() OVER (PARTITION BY is.total_on_hand > 0 ORDER BY COALESCE(cs.total_sold, 0) + COALESCE(ss.total_store_sales, 0) DESC) AS overall_sales_rank,
    crr.c_first_name || ' ' || crr.c_last_name AS top_customer
FROM 
    item i
LEFT JOIN 
    item_sales cs ON i.i_item_sk = cs.ws_item_sk
LEFT JOIN 
    store_sales_summary ss ON i.i_item_sk = ss.ss_item_sk
LEFT JOIN 
    inventory_status is ON i.i_item_sk = is.inv_item_sk
LEFT JOIN 
    customer_rank cr ON cr.purchase_rank = 1
WHERE 
    (cs.total_sold IS NULL OR cs.total_sold > 10)
    AND (ss.total_store_sales IS NULL OR ss.total_store_sales > 10)
ORDER BY 
    total_combined_sales DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
