
WITH RECURSIVE Customer_Income AS (
    SELECT c.c_customer_sk,
           SUM(CASE
               WHEN d.d_year = 2022 AND d.d_moy BETWEEN 1 AND 6 THEN ws_net_paid
               ELSE 0
           END) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk
),
Recent_Sales AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_net_paid) AS recent_sales_total
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_bill_customer_sk
),
Customer_Demo AS (
    SELECT cd.cd_demo_sk,
           cd_cd_gender,
           cd.cd_marital_status,
           cd_purchase_estimate,
           ci.total_spent,
           COALESCE(rs.recent_sales_total, 0) AS recent_sales_total,
           CASE 
               WHEN ci.total_spent > 1000 AND rs.recent_sales_total > 0 THEN 'High Value'
               WHEN ci.total_spent BETWEEN 500 AND 1000 THEN 'Moderate Value'
               ELSE 'Low Value'
           END AS value_segment
    FROM customer_demographics cd
    LEFT JOIN Customer_Income ci ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN Recent_Sales rs ON rs.ws_bill_customer_sk = c.c_customer_sk
),
Demographic_Stats AS (
    SELECT cd.value_segment,
           COUNT(*) AS num_customers,
           AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM Customer_Demo cd
    GROUP BY cd.value_segment
)
SELECT ds.value_segment,
       ds.num_customers,
       ds.avg_purchase_estimate,
       (SELECT COUNT(DISTINCT ca.ca_address_sk) 
        FROM customer_address ca 
        WHERE ca.ca_country IS NULL OR ca.ca_country = 'USA') AS address_count
FROM Demographic_Stats ds
WHERE ds.num_customers > 10
ORDER BY ds.num_customers DESC
UNION ALL
SELECT 'Other', COUNT(*), NULL
FROM customer
WHERE c_customer_sk NOT IN (SELECT c_current_cdemo_sk FROM customer_demographics);
