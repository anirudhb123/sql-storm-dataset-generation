
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 1 as level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
DailyReturns AS (
    SELECT 
        dd.d_date, 
        SUM(sr_return_quantity) AS total_returned_quantity, 
        SUM(sr_return_amt_inc_tax) AS total_returned_amt
    FROM date_dim dd
    LEFT JOIN store_returns sr ON dd.d_date_sk = sr.sr_returned_date_sk
    GROUP BY dd.d_date
),
TotalSales AS (
    SELECT 
        dd.d_date,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        AVG(ws.ws_sales_price) AS average_sales_price
    FROM date_dim dd
    JOIN web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY dd.d_date
),
SalesComparison AS (
    SELECT 
        dr.d_date,
        COALESCE(dy.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(dy.total_returned_amt, 0) AS total_returned_amt,
        COALESCE(ts.total_sales_amount, 0) AS total_sales_amount,
        CASE 
            WHEN ts.total_sales_amount > 0 THEN TRUNCATE(100.0 * dy.total_returned_amt / ts.total_sales_amount, 2)
            ELSE 0 
        END AS return_percentage
    FROM DailyReturns dy
    FULL OUTER JOIN TotalSales ts ON dy.d_date = ts.d_date
),
HighValueCustomers AS (
    SELECT c.c_customer_sk, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           cd.cd_credit_rating,
           SUM(total_sales_amount) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_credit_rating
    HAVING total_spent >= 10000
),
FinalReport AS (
    SELECT 
        hc.full_name,
        hc.cd_credit_rating,
        COALESCE(sc.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(sc.return_percentage, 0) AS return_percentage,
        ROW_NUMBER() OVER (PARTITION BY hc.cd_credit_rating ORDER BY hc.total_spent DESC) AS rank
    FROM HighValueCustomers hc
    LEFT JOIN SalesComparison sc ON 1=1
)
SELECT * FROM FinalReport
WHERE rank <= 10
ORDER BY cd_credit_rating, total_spent DESC;
