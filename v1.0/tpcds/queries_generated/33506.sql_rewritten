WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_marital_status, 
           cd.cd_gender, 
           0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_customer_sk < 1000  

    UNION ALL

    SELECT ch.c_customer_sk, 
           ch.c_first_name, 
           ch.c_last_name, 
           cd.cd_marital_status, 
           cd.cd_gender, 
           ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON c.c_current_cdemo_sk = ch.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE level < 5  
),

AggregateSales AS (
    SELECT 
        ws_bill_cdemo_sk AS demo_sk,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_cdemo_sk
),

FilteredSales AS (
    SELECT demo_sk, total_net_paid, order_count
    FROM AggregateSales
    WHERE total_net_paid > 1000  
)

SELECT ch.c_first_name, 
       ch.c_last_name, 
       ch.cd_marital_status, 
       ch.cd_gender, 
       fs.total_net_paid, 
       fs.order_count, 
       ROW_NUMBER() OVER (PARTITION BY ch.cd_gender ORDER BY fs.total_net_paid DESC) AS gender_rank
FROM CustomerHierarchy ch
LEFT JOIN FilteredSales fs ON ch.c_customer_sk = fs.demo_sk
WHERE fs.total_net_paid IS NOT NULL  
ORDER BY ch.cd_gender, fs.total_net_paid DESC;