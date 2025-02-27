
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_birth_country,
           1 AS depth
    FROM customer c
    WHERE c.c_customer_sk IN (
        SELECT distinct cr_returning_customer_sk
        FROM catalog_returns
        WHERE cr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
    )
    UNION ALL
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_birth_country,
           ch.depth + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesSummary AS (
    SELECT w.ws_sold_date_sk,
           SUM(ws_sales_price) AS total_sales,
           COUNT(ws_order_number) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY w.ws_sold_date_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales w
    JOIN date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY w.ws_sold_date_sk
),
CustomerMetrics AS (
    SELECT cd.cd_gender,
           SUM(ws.ws_sales_price) AS total_spent,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT w.ws_sold_date_sk
        FROM SalesSummary w
        WHERE w.total_sales > 1000
    )
    GROUP BY cd.cd_gender
)
SELECT ch.c_first_name,
       ch.c_last_name,
       ch.c_birth_country,
       cm.total_spent,
       cm.order_count,
       ss.total_sales
FROM CustomerHierarchy ch
LEFT JOIN CustomerMetrics cm ON ch.c_customer_sk = cm.cd_gender
JOIN SalesSummary ss ON ss.ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
WHERE ch.depth <= 3
ORDER BY cm.total_spent DESC NULLS LAST;
