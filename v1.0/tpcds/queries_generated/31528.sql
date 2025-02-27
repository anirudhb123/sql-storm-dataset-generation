
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_current_cdemo_sk,
        1 AS level
    FROM 
        customer
    WHERE 
        c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk 
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        CustomerHierarchy ch ON ws.ws_bill_customer_sk = ch.c_customer_sk
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit
    FROM 
        SalesData sd
    WHERE 
        sd.rn <= 5
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(t.total_quantity, 0) AS top_quantity,
    COALESCE(t.total_profit, 0) AS top_profit,
    (SELECT COUNT(DISTINCT ws.ws_bill_customer_sk) 
     FROM web_sales ws 
     WHERE ws.ws_item_sk = i.i_item_sk) AS unique_customers,
    (SELECT COUNT(*) 
     FROM web_returns wr 
     WHERE wr.wr_item_sk = i.i_item_sk) AS total_returns
FROM 
    item i
LEFT JOIN 
    TopItems t ON i.i_item_sk = t.ws_item_sk
WHERE 
    i.i_current_price > 10.00
ORDER BY 
    top_profit DESC, 
    top_quantity DESC 
LIMIT 10;
