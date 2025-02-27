
WITH RecursiveReturnData AS (
    SELECT 
        wr.returning_customer_sk,
        wr.return_quantity,
        wr.return_amt,
        wr.refunded_cash,
        wr.return_time_sk,
        wr.order_number,
        ROW_NUMBER() OVER (PARTITION BY wr.returning_customer_sk ORDER BY wr.returned_date_sk ASC, wr.return_time_sk ASC) AS rn
    FROM web_returns wr
    WHERE wr.return_quantity IS NOT NULL AND wr.return_quantity > 0
),
HighValueReturns AS (
    SELECT 
        r.returning_customer_sk,
        SUM(r.return_amt) AS total_return_amount,
        COUNT(*) AS return_count,
        MAX(r.return_quantity) AS max_return_quantity
    FROM RecursiveReturnData r
    WHERE r.total_return_amount > (SELECT AVG(return_amt) * 1.5 FROM RecursiveReturnData)
    GROUP BY r.returning_customer_sk
)
SELECT 
    ca.city,
    ca.state,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(COALESCE(d.d_year, 0)) AS total_years_as_customer,
    AVG(COALESCE(sh.shipping_cost, 0)) AS avg_shipping_cost,
    ROUND(AVG(hvr.total_return_amount), 2) AS avg_high_value_return,
    ROW_NUMBER() OVER (PARTITION BY ca.city ORDER BY SUM(r.return_count) DESC) AS city_rank
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN (
    SELECT 
        wr.returning_customer_sk, 
        SUM(wr.wr_return_ship_cost) AS shipping_cost
    FROM web_returns wr
    GROUP BY wr.returning_customer_sk
) sh ON c.c_customer_sk = sh.returning_customer_sk
LEFT JOIN HighValueReturns hvr ON c.c_customer_sk = hvr.returning_customer_sk
JOIN date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk 
WHERE ca.state IS NOT NULL AND ca.city IS NOT NULL
GROUP BY ca.city, ca.state
HAVING COUNT(DISTINCT c.c_customer_sk) > 5 AND 
       EXISTS (SELECT 1 FROM store s WHERE s.s_state = ca.state AND s.s_current_date > '2023-01-01')
ORDER BY customer_count DESC, total_years_as_customer ASC;
