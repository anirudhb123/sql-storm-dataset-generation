
WITH RECURSIVE sales_hierarchy AS (
    SELECT cs_customer_sk, cs_sales_price, s_store_sk
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT cs.cs_customer_sk, cs.cs_sales_price * 1.1 AS cs_sales_price, s.s_store_sk
    FROM catalog_sales cs
    JOIN sales_hierarchy sh ON cs.cs_customer_sk = sh.cs_customer_sk
    WHERE sh.cs_sales_price < 500
),
address_info AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address
    FROM customer_address
    WHERE ca_city IS NOT NULL
),
return_metrics AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        AVG(sr_return_amt_inc_tax) AS avg_return_amount
    FROM store_returns
    GROUP BY sr_item_sk
),
customer_details AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count
    FROM customer
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY c_customer_sk, cd_gender, cd_marital_status, cd_credit_rating
),
final_metrics AS (
    SELECT 
        sh.cs_customer_sk,
        SUM(sh.cs_sales_price) AS total_sales,
        COALESCE(AVG(rm.total_returns), 0) AS avg_returns,
        SUM(CASE WHEN cd.marital_status = 'M' THEN sh.cs_sales_price ELSE 0 END) AS married_sales
    FROM sales_hierarchy sh
    LEFT JOIN return_metrics rm ON sh.s_store_sk = rm.s_store_sk
    LEFT JOIN customer_details cd ON sh.cs_customer_sk = cd.c_customer_sk
    GROUP BY sh.cs_customer_sk
)
SELECT 
    fm.cs_customer_sk,
    fm.total_sales,
    fm.avg_returns,
    fi.full_address,
    CASE 
        WHEN fm.total_sales IS NULL THEN 'No Sales'
        WHEN fm.avg_returns > 0 THEN 'Frequent Returns'
        ELSE 'Healthy Customer'
    END AS customer_health
FROM final_metrics fm
JOIN address_info fi ON fm.cs_customer_sk = fi.ca_address_id
WHERE fm.total_sales IS NOT NULL
AND fi.full_address IS NOT NULL
ORDER BY fm.total_sales DESC
LIMIT 100;
