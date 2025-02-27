
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year >= 1980

    UNION ALL

    SELECT 
        ch.c_customer_sk,
        ch.c_customer_id,
        ch.c_first_name,
        ch.c_last_name,
        ch.cd_demo_sk,
        ch.cd_gender,
        ch.cd_marital_status,
        ch.cd_purchase_estimate,
        level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON c.c_customer_sk = ch.c_customer_sk
    WHERE c.c_first_shipto_date_sk IS NOT NULL
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_payment
    FROM web_sales
    WHERE ws_sold_date_sk > 20210101
    GROUP BY ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        ch.c_customer_id,
        ch.c_first_name,
        ch.c_last_name,
        ss.total_net_profit,
        ss.total_orders,
        ss.avg_payment,
        ROW_NUMBER() OVER (ORDER BY ss.total_net_profit DESC) AS rank
    FROM CustomerHierarchy ch
    JOIN SalesSummary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
    WHERE ss.total_net_profit > 1000
)
SELECT 
    custom.c_customer_id,
    custom.c_first_name,
    custom.c_last_name,
    custom.total_net_profit,
    custom.total_orders,
    custom.avg_payment,
    CASE 
        WHEN custom.total_orders > 10 THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS engagement_level
FROM HighValueCustomers custom
WHERE custom.rank <= 100
ORDER BY custom.total_net_profit DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
