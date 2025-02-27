
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM
        web_sales
    WHERE
        ws_sold_date_sk > 2000000
    GROUP BY
        ws_item_sk
),
customer_info AS (
    SELECT
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_dep_count,
        cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS gender_rank
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
)
SELECT 
    ca.city AS "Address City",
    SUM(s.total_sales) AS "Total Sales",
    COUNT(DISTINCT ci.c_customer_sk) AS "Distinct Customers",
    (SELECT COUNT(*) FROM customer WHERE c_birth_year IS NULL) AS "Unknown Birth Year Count",
    COUNT(DISTINCT r.r_reason_sk) FILTER (WHERE r.r_reason_desc IS NOT NULL) AS "Distinct Reasons"
FROM 
    customer_address ca
LEFT JOIN 
    store_sales ss ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN 
    sales_summary s ON s.ws_item_sk = ss.ss_item_sk
FULL OUTER JOIN 
    customer_info ci ON ci.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    reason r ON r.r_reason_sk = ss.ss_promo_sk
WHERE 
    (ca.ca_city IS NOT NULL OR ca.ca_state IS NOT NULL)
    AND (s.total_sales > 100.00 OR s.total_quantity IS NULL)
    AND (ci.cd_purchase_estimate > 1000 AND ci.cd_credit_rating IS NOT NULL OR ci.cd_dep_count BETWEEN 1 AND 5)
GROUP BY 
    ca.city
HAVING 
    SUM(s.total_sales) > COALESCE((SELECT AVG(total_sales) FROM sales_summary), 0)
ORDER BY 
    "Total Sales" DESC
LIMIT 10;
