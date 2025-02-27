
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk,
           0 AS level
    FROM customer
    WHERE c_customer_sk IN (SELECT sr_customer_sk FROM store_returns)
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 5
),
TotalSales AS (
    SELECT ws_bill_customer_sk AS customer_sk, 
           SUM(ws_net_paid_inc_tax) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerSales AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name,
           COALESCE(ts.total_sales, 0) AS total_sales
    FROM CustomerHierarchy ch
    LEFT JOIN TotalSales ts ON ch.c_customer_sk = ts.customer_sk
),
PurchaseStats AS (
    SELECT cd.cd_gender, hd.hd_income_band_sk,
           AVG(cs.total_sales) AS avg_sales, 
           COUNT(cs.c_customer_sk) AS customer_count
    FROM CustomerSales cs
    LEFT JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY cd.cd_gender, hd.hd_income_band_sk
)

SELECT ps.cd_gender, ib.ib_lower_bound, ib.ib_upper_bound, ps.avg_sales, ps.customer_count
FROM PurchaseStats ps
JOIN income_band ib ON ps.hd_income_band_sk = ib.ib_income_band_sk
WHERE ps.avg_sales > (SELECT AVG(avg_sales) FROM PurchaseStats)
ORDER BY ps.cd_gender, ib.ib_lower_bound;
