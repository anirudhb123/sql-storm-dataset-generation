
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sold, 
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
    HAVING 
        total_orders > 5
),
inventory_info AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        COALESCE(CAST(NULLIF(SUM(sr_return_quantity), 0) AS DECIMAL(10,2)), 0) AS total_returns
    FROM 
        inventory inv
    LEFT JOIN 
        store_returns sr ON inv.inv_item_sk = sr.sr_item_sk
    GROUP BY 
        inv.inv_item_sk, inv.inv_quantity_on_hand
),
final_report AS (
    SELECT 
        cp.c_customer_sk,
        cp.c_first_name,
        cp.c_last_name,
        cp.cd_gender,
        cp.total_orders,
        cp.total_spent,
        is.iv_quantity_on_hand,
        is.total_returns,
        rs.total_sold
    FROM 
        customer_purchases cp
    JOIN 
        inventory_info is ON (rs.ws_item_sk IN (SELECT DISTINCT ws_item_sk FROM ranked_sales WHERE sales_rank = 1))
    JOIN 
        ranked_sales rs ON cp.total_spent >= 1000 AND rs.total_sold > 50
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.total_orders,
    fr.total_spent,
    fr.iv_quantity_on_hand - fr.total_returns AS net_inventory
FROM 
    final_report fr
WHERE 
    fr.total_spent IS NOT NULL 
    AND fr.cd_gender IS NOT NULL
ORDER BY 
    fr.total_spent DESC;
