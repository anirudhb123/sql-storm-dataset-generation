
WITH RECURSIVE CustomerTree AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk, cd.cd_gender, 
           NULL AS parent_sk, 1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk, cd.cd_gender, 
           ct.c_customer_sk AS parent_sk, ct.level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerTree ct ON c.c_customer_sk <> ct.c_customer_sk
    WHERE c.c_birth_year > 1980 AND cd.cd_marital_status = 'M'
),
FilteredSales AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity, SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 3
    GROUP BY ws.ws_item_sk
),
RankedSales AS (
    SELECT fs.ws_item_sk, fs.total_quantity, fs.total_sales, 
           RANK() OVER (ORDER BY fs.total_sales DESC) AS sales_rank
    FROM FilteredSales fs
),
CustomerReturns AS (
    SELECT sr.sr_customer_sk, SUM(sr.sr_return_quantity) AS total_returns
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
),
FinalReport AS (
    SELECT ct.c_first_name, ct.c_last_name, 
           COALESCE(cs.total_quantity, 0) AS total_quantity, 
           COALESCE(cs.total_sales, 0) AS total_sales, 
           COALESCE(cr.total_returns, 0) AS total_returns
    FROM CustomerTree ct
    LEFT JOIN RankedSales cs ON ct.c_customer_sk = cs.ws_item_sk
    LEFT JOIN CustomerReturns cr ON ct.c_customer_sk = cr.sr_customer_sk
)
SELECT f.c_first_name, f.c_last_name, f.total_quantity, 
       f.total_sales, f.total_returns, 
       CASE 
           WHEN f.total_returns > 0 THEN 'Returned'
           ELSE 'Not Returned' 
       END AS return_status
FROM FinalReport f
WHERE f.total_sales > 1000
ORDER BY f.total_sales DESC;
