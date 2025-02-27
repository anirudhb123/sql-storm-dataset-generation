
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           cd.cd_marital_status, cd.cd_gender, cd.cd_purchase_estimate, 
           ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY c.c_birth_year) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IS NOT NULL
)
SELECT 
    ch.c_customer_id, 
    ch.c_first_name, 
    ch.c_last_name, 
    ch.cd_marital_status,
    COUNT(CASE WHEN cs.ws_sales_price > 100 THEN 1 END) AS high_value_sales,
    SUM(cs.ws_sales_price) AS total_sales,
    AVG(NULLIF(cs.ws_sales_price, 0)) AS avg_sales_value,
    (SELECT DISTINCT sm.sm_type 
     FROM ship_mode sm 
     WHERE sm.sm_ship_mode_sk IN (
         SELECT DISTINCT ws.ws_ship_mode_sk 
         FROM web_sales ws 
         WHERE ws.ws_bill_customer_sk = ch.c_customer_sk
     )) AS preferred_ship_mode,
    CASE 
        WHEN MAX(cd.cd_purchase_estimate) IS NULL THEN 'Unknown'
        ELSE CASE 
            WHEN MAX(cd.cd_purchase_estimate) < 500 THEN 'Low'
            WHEN MAX(cd.cd_purchase_estimate) BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'High'
        END 
    END AS purchase_estimate_category,
    DENSE_RANK() OVER (ORDER BY SUM(cs.ws_sales_price) DESC) AS sales_rank
FROM web_sales cs
JOIN customer_hierarchy ch ON cs.ws_bill_customer_sk = ch.c_customer_sk
WHERE cs.ws_sold_date_sk = (
    SELECT MAX(d.d_date_sk)
    FROM date_dim d 
    WHERE d.d_date BETWEEN '2023-10-01' AND '2023-10-31'
)
GROUP BY ch.c_customer_id, ch.c_first_name, ch.c_last_name, ch.cd_marital_status
HAVING COUNT(*) > 5 OR MAX(cs.ws_sales_price) > 200
ORDER BY sales_rank, ch.c_customer_id DESC
LIMIT 10;
