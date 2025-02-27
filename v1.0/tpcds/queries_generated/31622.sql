
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rn
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY ws.bill_customer_sk
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(ca.ca_city, 'Unknown City') AS city,
    SUM(ISNULL(ws.ws_net_profit, 0) + ISNULL(cs.cs_net_profit, 0)) AS total_profit,
    RANK() OVER (ORDER BY SUM(ISNULL(ws.ws_net_profit, 0) + ISNULL(cs.cs_net_profit, 0)) DESC) AS profit_rank
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
WHERE c.c_preferred_cust_flag = 'Y'
AND EXISTS (
    SELECT 1 
    FROM sales_cte
    WHERE sales_cte.bill_customer_sk = c.c_customer_sk
    AND sales_cte.total_net_profit > 1000
)
GROUP BY c.c_first_name, c.c_last_name, ca.ca_city
HAVING SUM(ISNULL(ws.ws_net_profit, 0) + ISNULL(cs.cs_net_profit, 0)) > 500
ORDER BY total_profit DESC
LIMIT 10;
