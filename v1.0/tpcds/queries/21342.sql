
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 
           c_current_addr_sk,
           1 AS level 
    FROM customer 
    WHERE c_preferred_cust_flag = 'Y'
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           c.c_current_addr_sk,
           ch.level + 1 
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk 
    WHERE ch.level < 5
), 
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk 
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_return_amt 
    FROM store_returns 
    GROUP BY sr_item_sk
),
FinalReport AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        sd.ws_item_sk,
        sd.total_quantity,
        COALESCE(rd.total_returned, 0) AS total_returned,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(rd.total_returned, 0) > 0 THEN 
                ROUND((sd.total_net_paid - COALESCE(rd.total_return_amt, 0)) / NULLIF(sd.total_net_paid, 0), 4)
            ELSE 
                1.0 
        END AS net_profit_ratio
    FROM CustomerHierarchy ch
    INNER JOIN SalesData sd ON ch.c_current_addr_sk = sd.ws_item_sk
    LEFT JOIN ReturnData rd ON sd.ws_item_sk = rd.sr_item_sk
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    COUNT(DISTINCT fr.ws_item_sk) AS unique_items,
    SUM(fr.total_quantity) AS total_quantity_sold,
    AVG(fr.net_profit_ratio) AS average_net_profit_ratio
FROM FinalReport fr
JOIN customer c ON fr.c_customer_sk = c.c_customer_sk
WHERE (fr.total_quantity > 100 OR fr.total_returned = 0)
AND (fr.net_profit_ratio IS NOT NULL AND fr.net_profit_ratio > 0)
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
HAVING AVG(fr.net_profit_ratio) > 0.1
ORDER BY unique_items DESC, total_quantity_sold DESC
FETCH FIRST 10 ROWS ONLY;
