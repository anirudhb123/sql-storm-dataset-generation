
WITH formatted_customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COALESCE(ca.city, 'Unknown') AS city,
        COALESCE(ca.state, 'Unknown') AS state,
        COALESCE(ca.country, 'Unknown') AS country,
        cd.education_status AS education,
        cd.marital_status AS marital_status,
        cd.purchase_estimate AS purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
filtered_customer_info AS (
    SELECT 
        c.customer_sk,
        c.full_name,
        COUNT(CASE WHEN o.ws_item_sk IS NOT NULL THEN 1 END) AS purchase_count,
        SUM(COALESCE(o.ws_net_profit, 0)) AS total_profit,
        COUNT(CASE WHEN o.cs_item_sk IS NOT NULL THEN 1 END) AS catalog_purchase_count,
        SUM(COALESCE(o.cs_net_profit, 0)) AS total_catalog_profit
    FROM 
        formatted_customer_info c
    LEFT JOIN 
        web_sales o ON c.c_customer_sk = o.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales os ON c.c_customer_sk = os.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.full_name
)
SELECT 
    f.full_name,
    f.gender,
    f.city,
    f.state,
    f.country,
    f.education,
    f.marital_status,
    f.purchase_estimate,
    (COALESCE(purchase_count, 0) + COALESCE(catalog_purchase_count, 0)) AS total_purchases,
    (COALESCE(total_profit, 0) + COALESCE(total_catalog_profit, 0)) AS overall_profit
FROM 
    filtered_customer_info f
WHERE 
    f.purchase_count > 5 OR f.catalog_purchase_count > 5
ORDER BY 
    overall_profit DESC, total_purchases DESC
LIMIT 100;
