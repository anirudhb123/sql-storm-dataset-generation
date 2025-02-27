
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales
    WHERE 
        ws_net_profit > 0
),
CustomerProfits AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_profit) > 10000
),
ItemReturnCounts AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM 
        catalog_returns AS cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    ca.ca_city,
    SUM(total_profit) AS aggregated_profit,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    COALESCE(SUM(ir.return_count), 0) AS total_returns
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    CustomerProfits AS cp ON cp.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    ItemReturnCounts AS ir ON ir.cr_item_sk IN (
        SELECT i_item_sk
        FROM RankedSales 
        WHERE rank_profit <= 3
    )
GROUP BY 
    ca.ca_city
ORDER BY 
    aggregated_profit DESC
FETCH FIRST 10 ROWS ONLY;
