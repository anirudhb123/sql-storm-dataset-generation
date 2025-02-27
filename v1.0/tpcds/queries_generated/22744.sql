
WITH RankedSales AS (
    SELECT ws.bill_customer_sk,
           SUM(ws.net_paid_inc_tax) AS total_net_paid,
           RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_paid_inc_tax) DESC) AS rank,
           ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.sold_date_sk DESC) AS order_rank
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY ws.bill_customer_sk
),
AddressInfo AS (
    SELECT DISTINCT ca.city, ca.state, ca.country,
           CASE 
               WHEN (ca.city IS NOT NULL AND ca.state IS NOT NULL) 
                   THEN CONCAT(ca.city, ', ', ca.state)
               ELSE COALESCE(ca.country, 'Unknown') 
           END AS location
    FROM customer_address ca
),
AggregatedReturns AS (
    SELECT cr.refunded_customer_sk,
           COUNT(DISTINCT cr.return_number) as total_returns,
           SUM(cr.return_amount) AS total_returned_amount
    FROM catalog_returns cr
    WHERE cr.return_quantity > 0
    GROUP BY cr.refunded_customer_sk
)
SELECT a.location,
       rs.bill_customer_sk,
       rs.total_net_paid,
       ar.total_returns,
       ar.total_returned_amount,
       CASE 
           WHEN ar.total_returned_amount > 1000 THEN 'High Returner'
           WHEN ar.total_returned_amount BETWEEN 500 AND 1000 THEN 'Medium Returner'
           ELSE 'Low Returner' 
       END AS returner_category
FROM RankedSales rs
LEFT JOIN AddressInfo a ON a.city = 'Seattle' AND a.state = 'WA'
LEFT JOIN AggregatedReturns ar ON rs.bill_customer_sk = ar.refunded_customer_sk
WHERE rs.rank <= 10 AND (ar.total_returns IS NULL OR ar.total_returns > 2)
ORDER BY rs.total_net_paid DESC, ar.total_returned_amount ASC
LIMIT 20;
