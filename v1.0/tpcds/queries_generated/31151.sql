
WITH RECURSIVE DateRange AS (
    SELECT d_date_sk, d_date FROM date_dim WHERE d_date >= '2021-01-01'
    UNION ALL
    SELECT d_date_sk + 1, DATE_ADD(d_date, INTERVAL 1 DAY)
    FROM DateRange
    WHERE d_date < '2022-01-01'
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent,
        AVG(ws_ext_sales_price) AS avg_order_value
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk
),
DailyReturns AS (
    SELECT 
        dr.d_date AS return_date,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amount
    FROM DateRange dr
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = dr.d_date_sk
    GROUP BY dr.d_date
),
SalesWithReturns AS (
    SELECT 
        ds.return_date,
        cs.c_customer_sk,
        cs.total_orders,
        cs.total_spent,
        cs.avg_order_value,
        dr.total_returns,
        dr.total_return_amount
    FROM DailyReturns dr
    JOIN CustomerStats cs ON ds.return_date = dr.return_date
)
SELECT 
    ss.c_customer_sk,
    ss.total_orders,
    ss.total_spent,
    ss.total_return_amount,
    CASE 
        WHEN ss.total_spent IS NULL THEN 'No Purchases'
        WHEN ss.total_spent < 100 THEN 'Low Spender'
        WHEN ss.total_spent BETWEEN 100 AND 500 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS customer_segment,
    RANK() OVER (PARTITION BY ss.customer_segment ORDER BY ss.total_spent DESC) AS rank_within_segment
FROM SalesWithReturns ss
WHERE ss.total_returns > 0
ORDER BY ss.total_return_amount DESC;
