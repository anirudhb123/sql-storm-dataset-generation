
WITH CTE_Sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
CTE_Inventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
CTE_Customer AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        hd.hd_buy_potential,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
CTE_Returns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    cs.total_quantity,
    cs.total_sales,
    cs.avg_net_profit,
    inv.total_inventory,
    c.cd_gender,
    c.hd_buy_potential,
    c.cd_marital_status,
    c.cd_purchase_estimate,
    COALESCE(r.return_count, 0) AS return_count,
    COALESCE(r.total_return_amount, 0) AS total_return_amount
FROM 
    item i
LEFT JOIN 
    CTE_Sales cs ON i.i_item_sk = cs.ws_item_sk
LEFT JOIN 
    CTE_Inventory inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN 
    CTE_Customer c ON c.c_customer_sk = (SELECT c_customer_sk FROM customer ORDER BY RANDOM() LIMIT 1)
LEFT JOIN 
    CTE_Returns r ON i.i_item_sk = r.sr_item_sk
WHERE 
    (cs.total_sales > 1000 OR inv.total_inventory < 50)
    AND c.cd_gender IS NOT NULL
ORDER BY 
    cs.total_sales DESC, cs.total_quantity ASC
FETCH FIRST 100 ROWS ONLY;
