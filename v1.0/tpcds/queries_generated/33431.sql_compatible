
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        c.c_current_cdemo_sk,
        1 AS level
    FROM 
        customer c
    WHERE 
        c.c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        c.c_current_cdemo_sk,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk 
    WHERE 
        ch.level < 5
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amt) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    CONCAT(ch.c_first_name, ' ', ch.c_last_name) AS customer_name,
    ca.ca_city,
    sd.total_quantity,
    sd.total_net_profit,
    COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN sd.total_net_profit > 0 THEN 'Profit' 
        WHEN sd.total_net_profit < 0 THEN 'Loss' 
        ELSE 'Neutral' 
    END AS profit_loss_status
FROM 
    CustomerHierarchy ch
JOIN 
    customer_address ca ON ch.c_current_addr_sk = ca.ca_address_sk
JOIN 
    SalesData sd ON ch.c_current_cdemo_sk = sd.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON sd.ws_item_sk = cr.cr_item_sk
WHERE 
    ch.level = 1 
    AND ca.ca_state = 'CA' 
    AND sd.sales_rank <= 10
ORDER BY 
    sd.total_net_profit DESC;
