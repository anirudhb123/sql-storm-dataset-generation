
WITH customer_with_income AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), 
item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
), 
inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS available_stock
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
sales_and_inventory AS (
    SELECT 
        c.customer_id,
        cw.total_quantity,
        cw.total_sales,
        is.available_stock
    FROM 
        customer_with_income c
    LEFT JOIN 
        item_sales cw ON c.c_customer_id = cw.ws_item_sk
    LEFT JOIN 
        inventory_status is ON cw.ws_item_sk = is.inv_item_sk
)
SELECT 
    customer_id,
    COUNT(*) AS number_of_purchases,
    SUM(total_quantity) AS total_items_purchased,
    SUM(total_sales) AS total_spent,
    AVG(available_stock) AS average_stock_level
FROM 
    sales_and_inventory
GROUP BY 
    customer_id
ORDER BY 
    total_spent DESC;
