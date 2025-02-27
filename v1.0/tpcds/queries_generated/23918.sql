
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_zip, 0 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL

    UNION ALL

    SELECT ca_address_sk, ca_city, ca_state, ca_zip, level + 1
    FROM customer_address
    JOIN address_hierarchy ON address_hierarchy.ca_city = customer_address.ca_city
    WHERE address_hierarchy.level < 5
),
customer_with_income AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer c
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ch.city,
    ch.zip,
    c.first_name,
    c.last_name,
    c.gender,
    c.marital_status,
    cs.total_sales,
    cs.order_count,
    CASE 
        WHEN cs.sales_rank = 1 THEN 'Top Buyer' 
        WHEN cs.sales_rank BETWEEN 2 AND 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer' 
    END AS buyer_type,
    NULLIF(c.c_email_address, '') AS email_address,
    (SELECT 
        SUM(CASE 
            WHEN ws_ext_discount_amt > 0 THEN ws_ext_discount_amt 
            ELSE 0 
        END) 
    FROM web_sales ws 
    WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS total_discounts
FROM address_hierarchy ch
JOIN customer_with_income c ON ch.ca_zip = (
    SELECT DISTINCT ca_zip 
    FROM customer_address 
    WHERE ca_city = ch.ca_city 
    LIMIT 1
)
JOIN sales_summary cs ON c.c_customer_sk = cs.customer_id
WHERE c.marital_status = 'M'
  AND c.purchase_estimate > 50000
  AND (c.gender = 'F' OR c.gender IS NULL)
ORDER BY ch.city, total_sales DESC
LIMIT 100 OFFSET 50;

