
WITH RECURSIVE CustomerCTE AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_year, c_current_cdemo_sk
    FROM customer
    WHERE c_birth_year IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year, c.c_current_cdemo_sk
    FROM customer AS c
    JOIN CustomerCTE AS ct ON c.c_current_cdemo_sk = ct.c_current_cdemo_sk
    WHERE c.c_customer_sk <> ct.c_customer_sk
),
ReturnStats AS (
    SELECT sr_customer_sk, SUM(sr_return_quantity) AS total_returns, COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM store_returns
    GROUP BY sr_customer_sk
),
SalesStats AS (
    SELECT ws_bill_customer_sk, SUM(ws_sales_price) AS total_sales, AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           COALESCE(rs.total_returns, 0) AS total_returns, COALESCE(ss.total_sales, 0) AS total_sales,
           COALESCE(ss.avg_sales_price, 0) AS avg_sales_price
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN ReturnStats AS rs ON c.c_customer_sk = rs.sr_customer_sk
    LEFT JOIN SalesStats AS ss ON c.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status, 
       ci.total_returns, ci.total_sales, ci.avg_sales_price,
       CASE 
           WHEN ci.total_sales > 1000 THEN 'High'
           WHEN ci.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
           ELSE 'Low'
       END AS sales_category
FROM CustomerInfo AS ci
WHERE ci.cd_gender = 'F' AND ci.total_returns > 0
ORDER BY ci.total_sales DESC
LIMIT 10;
