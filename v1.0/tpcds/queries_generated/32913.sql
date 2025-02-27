
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        DATE(dd.d_date) AS sale_date
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2022
),
TopCustomers AS (
    SELECT 
        ch.c_customer_sk,
        CONCAT(ch.c_first_name, ' ', ch.c_last_name) AS full_name,
        SUM(sd.ws_net_profit) AS total_profit
    FROM CustomerHierarchy ch
    LEFT JOIN SalesData sd ON ch.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY ch.c_customer_sk, full_name
    HAVING SUM(sd.ws_net_profit) > 5000
),
CustomerRanked AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_profit DESC) AS rank
    FROM TopCustomers
)
SELECT
    cr.full_name,
    cr.total_profit,
    (SELECT COUNT(*) FROM store s WHERE s.s_number_employees > 50) AS store_count,
    (SELECT AVG(cd.cd_dep_count) FROM customer_demographics cd WHERE cd.cd_demo_sk IN (SELECT DISTINCT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL)) AS avg_dependent_count,
    (
        SELECT SUM(ws.ws_quantity)
        FROM web_sales ws
        JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
        WHERE w.web_country = 'USA' AND ws.ws_sales_price > 100
    ) AS total_expensive_items_sold,
    COALESCE((SELECT COUNT(*) FROM customer WHERE c_birth_year IS NULL), 0) AS null_birth_years
FROM CustomerRanked cr
WHERE cr.rank <= 10;
