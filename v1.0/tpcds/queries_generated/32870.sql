
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
Inventory_Summary AS (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
Customer_Summary AS (
    SELECT 
        c_current_cdemo_sk, 
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        c_current_cdemo_sk
),
Returns_Summary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    i.i_item_id,
    s.ws_quantity,
    s.ws_sales_price,
    i.i_current_price,
    i.i_item_desc,
    isnull(rs.total_returns, 0) AS total_returns,
    isnull(rs.total_return_value, 0) AS total_return_value,
    cs.customer_count,
    cs.avg_purchase_estimate,
    CASE 
        WHEN s.ws_net_profit > 0 THEN 'Profitable'
        WHEN s.ws_net_profit < 0 THEN 'Loss'
        ELSE 'Break-even'
    END AS Profit_Status
FROM 
    Sales_CTE s
JOIN 
    item i ON s.ws_item_sk = i.i_item_sk
LEFT JOIN 
    Returns_Summary rs ON s.ws_item_sk = rs.sr_item_sk
JOIN 
    Customer_Summary cs ON cs.c_current_cdemo_sk = i.i_brand_id
WHERE 
    s.rn = 1 
    AND s.ws_quantity > 10
    AND EXISTS (
        SELECT 1 
        FROM warehouse w 
        WHERE w.w_warehouse_sk = (SELECT MAX(w_warehouse_sk) FROM inventory inv WHERE inv.inv_item_sk = s.ws_item_sk) 
        AND w.w_country = 'USA'
    )
ORDER BY 
    s.ws_net_profit DESC, i.i_item_id
LIMIT 100;
