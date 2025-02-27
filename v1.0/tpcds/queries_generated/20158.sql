
WITH RankedReturns AS (
    SELECT 
        sr.customer_sk,
        sr.returned_date_sk,
        sr.return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr.customer_sk ORDER BY sr.returned_date_sk DESC) AS rnk
    FROM store_returns sr
    WHERE sr.return_quantity > 0
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    WHERE (ws.ws_sold_date_sk IS NOT NULL OR cs.cs_sold_date_sk IS NOT NULL)
    GROUP BY c.c_customer_sk
    HAVING total_spent > (SELECT AVG(total_spent) FROM (SELECT 
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_spent
        FROM customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
        LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
        GROUP BY c.c_customer_sk) AS avg_table)
),
CustomerReturnAnalysis AS (
    SELECT 
        hvc.c_customer_sk,
        COUNT(rr.return_quantity) AS return_count,
        SUM(rr.return_quantity) AS total_returned,
        AVG(COALESCE(rr.returned_date_sk, 0)) AS avg_return_date_sk
    FROM HighValueCustomers hvc
    LEFT JOIN RankedReturns rr ON hvc.c_customer_sk = rr.customer_sk AND rr.rnk <= 5
    GROUP BY hvc.c_customer_sk 
)
SELECT 
    ca.ca_city,
    SUM(COALESCE(ca.ca_gmt_offset, 0)) AS total_gmt_offset,
    AVG(cr.return_count) AS avg_returns_per_customer,
    COUNT(DISTINCT cr.c_customer_sk) AS unique_customers_with_returns,
    MAX(cr.total_returned) AS max_returned_quantity
FROM customer_address ca
JOIN CustomerReturnAnalysis cr ON NOT (cr.c_customer_sk IS NULL) 
LEFT OUTER JOIN store s ON s.s_store_sk = (SELECT MAX(s2.s_store_sk)
                                             FROM store s2
                                             WHERE s2.s_city = ca.ca_city) 
WHERE ca.ca_state = 'CA'
GROUP BY ca.ca_city
ORDER BY total_gmt_offset DESC 
FETCH FIRST 10 ROWS ONLY;
