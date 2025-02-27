
WITH processed_customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        ca_city,
        ca_state,
        cd_purchase_estimate,
        cd_credit_rating,
        CASE 
            WHEN cd_dep_count > 0 THEN 'Has Children' 
            ELSE 'No Children' 
        END AS children_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
aggregated_sales AS (
    SELECT 
        full_name,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count,
        AVG(CASE WHEN cd_credit_rating = 'Good' THEN ss_ext_sales_price ELSE NULL END) AS avg_good_credit_sales
    FROM processed_customer_info pci
    JOIN store_sales ss ON pci.c_customer_id = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON pci.c_customer_id = cs.cs_bill_customer_sk
    GROUP BY full_name
)
SELECT 
    pci.full_name,
    pci.gender,
    pci.ca_city,
    pci.ca_state,
    pci.cd_purchase_estimate,
    ag.total_sales,
    ag.order_count,
    ag.avg_good_credit_sales
FROM processed_customer_info pci
JOIN aggregated_sales ag ON pci.full_name = ag.full_name
WHERE ag.total_sales > 1000
ORDER BY ag.total_sales DESC, pci.full_name ASC
LIMIT 50;
