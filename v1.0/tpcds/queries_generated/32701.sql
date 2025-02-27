
WITH RECURSIVE CustomerPurchaseCTE AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating,
           cd.cd_dep_count,
           1 AS purchase_level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year >= 1980 -- Filtering for younger customers

    UNION ALL

    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating,
           cd.cd_dep_count,
           cp.purchase_level + 1
    FROM CustomerPurchaseCTE cp
    JOIN customer c ON cp.c_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 5000 -- Focusing on customers with higher estimate
),

SalesSummary AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           AVG(ws.ws_ext_sales_price) AS avg_sales_price
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY ws.ws_bill_customer_sk
),

RankedCustomers AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cs.total_net_profit,
           RANK() OVER (ORDER BY cs.total_net_profit DESC) AS sales_rank
    FROM customer c
    LEFT JOIN SalesSummary cs ON c.c_customer_sk = cs.ws_bill_customer_sk
),

HighValueCustomers AS (
    SELECT r.c_customer_sk,
           r.c_first_name,
           r.c_last_name,
           r.sales_rank
    FROM RankedCustomers r
    WHERE r.sales_rank <= 100
)

SELECT h.c_customer_sk,
       h.c_first_name,
       h.c_last_name,
       cp.purchase_level,
       COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating
FROM HighValueCustomers h
LEFT JOIN CustomerPurchaseCTE cp ON h.c_customer_sk = cp.c_customer_sk
LEFT JOIN customer_demographics cd ON h.c_customer_sk = cd.cd_demo_sk
WHERE h.c_first_name LIKE 'A%' OR h.c_last_name LIKE 'A%'
ORDER BY h.c_customer_sk, purchase_level DESC;
