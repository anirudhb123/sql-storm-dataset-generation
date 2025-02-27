
WITH RecursiveSales AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, 
           SUM(ws_net_paid) OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS cumulative_sales 
    FROM web_sales 
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
), 
CustomerDemographics AS (
    SELECT cd_gender, cd_marital_status, COUNT(c_customer_sk) AS customer_count 
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk 
    GROUP BY cd_gender, cd_marital_status
),
Promotions AS (
    SELECT p_promo_id, COUNT(*) AS promo_count 
    FROM promotion 
    WHERE p_discount_active = 'Y' 
    GROUP BY p_promo_id
),
SalesSummary AS (
    SELECT i_item_sk, SUM(ws_quantity) AS total_quantity, 
           AVG(ws_net_paid) AS avg_net_paid, 
           MAX(ws_net_paid) AS max_net_paid 
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
                                AND (SELECT MAX(d_date_sk) FROM date_dim) 
    GROUP BY i_item_sk
)
SELECT 
    ca.ca_city, 
    wd.cd_gender, 
    wd.cd_marital_status, 
    SUM(ss.total_quantity) AS total_quantity_sold, 
    AVG(ss.avg_net_paid) AS avg_net_sales_price, 
    sr.returned_item_count, 
    p.promo_count, 
    CASE 
        WHEN SUM(ss.total_quantity) > 100 THEN 'High Demand' 
        ELSE 'Low Demand' 
    END AS demand_category
FROM customer_address ca 
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk 
JOIN CustomerDemographics wd ON wd.customer_count > 0 
LEFT JOIN SalesSummary ss ON c.c_customer_sk = ss.i_item_sk 
LEFT JOIN (
    SELECT sr_item_sk, COUNT(*) AS returned_item_count 
    FROM store_returns 
    GROUP BY sr_item_sk
) sr ON ss.i_item_sk = sr.sr_item_sk 
LEFT JOIN Promotions p ON p.promo_count > 0 
GROUP BY ca.ca_city, wd.cd_gender, wd.cd_marital_status, sr.returned_item_count, p.promo_count 
HAVING SUM(ss.total_quantity) > 50 AND wd.cd_marital_status IS NOT NULL
ORDER BY total_quantity_sold DESC;
