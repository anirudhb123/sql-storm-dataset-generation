
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ship_mode_sk,
        sm.sm_type,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold
    FROM
        web_sales ws
    LEFT JOIN
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
),
TopProfitableItems AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.ws_net_profit
    FROM
        SalesData sd
    WHERE
        sd.rank_profit <= 5
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(tp.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(tp.ws_net_profit, 0) AS total_net_profit,
    SUM(CASE WHEN tp.ws_net_profit IS NOT NULL THEN tp.ws_net_profit ELSE 0 END) OVER (PARTITION BY i.i_item_id) AS cumulative_net_profit,
    MAX(sm.sm_type) AS preferred_shipping_method,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM 
    item i
LEFT JOIN 
    TopProfitableItems tp ON i.i_item_sk = tp.ws_item_sk
LEFT JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
GROUP BY 
    i.i_item_id, 
    i.i_item_desc
HAVING 
    SUM(COALESCE(tp.ws_net_profit, 0)) > 1000
ORDER BY 
    cumulative_net_profit DESC;
