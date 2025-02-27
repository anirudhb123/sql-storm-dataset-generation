
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
TopSales AS (
    SELECT 
        r.ws_order_number,
        SUM(r.ws_net_profit) AS total_net_profit,
        COUNT(r.ws_item_sk) AS total_items
    FROM 
        RankedSales r
    WHERE 
        r.rn <= 3
    GROUP BY 
        r.ws_order_number
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
    HAVING 
        COUNT(DISTINCT sr_ticket_number) > 0
)
SELECT 
    c.c_customer_id,
    COALESCE(a.ca_city, 'Unknown') AS customer_city,
    cs.total_net_profit,
    CASE 
        WHEN cr.total_returns IS NULL THEN 'No Returns'
        WHEN cr.total_returns > 5 THEN 'Frequent Returner'
        ELSE 'Occasional Returner'
    END AS return_status,
    CASE 
        WHEN cs.total_items >= 5 THEN 'Active Buyer'
        ELSE 'Casual Shopper'
    END AS buyer_status
FROM 
    customer c 
LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN TopSales cs ON cs.ws_order_number = (
        SELECT MAX(ws_order_number) 
        FROM web_sales 
        WHERE ws_bill_customer_sk = c.c_customer_sk
    )
LEFT JOIN CustomerReturns cr ON cr.sr_customer_sk = c.c_customer_sk
WHERE 
    (c.c_birth_month = 10 OR c.c_birth_month IS NULL)
    AND (c.c_birth_year IS NOT NULL OR cs.total_net_profit IS NOT NULL)
ORDER BY 
    cs.total_net_profit DESC NULLS LAST;
