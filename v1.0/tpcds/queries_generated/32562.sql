
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_order_number, 
        ws_quantity, 
        ws_net_paid, 
        1 AS Level
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    
    UNION ALL
    
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_quantity, 
        ws.ws_net_paid,
        c.Level + 1
    FROM web_sales ws
    JOIN SalesCTE c ON ws.ws_order_number = c.ws_order_number AND c.Level < 3
)
SELECT 
    ca.ca_city, 
    ca.ca_state,
    SUM(s.ws_net_paid) AS TotalNetPaid,
    COUNT(DISTINCT s.ws_order_number) AS UniqueOrders,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(s.ws_net_paid) DESC) AS StateRank
FROM SalesCTE s
JOIN customer c ON s.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN (SELECT ca_state, COUNT(*) AS SalesCount
            FROM customer_address
            GROUP BY ca_state
            HAVING COUNT(*) > 5) AS HeavyStates ON ca.ca_state = HeavyStates.ca_state
WHERE HeavyStates.ca_state IS NULL OR ca.ca_city IS NOT NULL
GROUP BY ca.ca_city, ca.ca_state
HAVING SUM(s.ws_net_paid) > 1000
ORDER BY TotalNetPaid DESC
LIMIT 10;
