
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CD.cd_demo_sk,
        CD.cd_gender,
        CD.cd_marital_status,
        0 AS level
    FROM 
        customer c
        JOIN customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    
    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CD.cd_demo_sk,
        CD.cd_gender,
        CD.cd_marital_status,
        ch.level + 1
    FROM 
        customer_hierarchy ch
        JOIN customer c ON ch.c_customer_sk = c.c_customer_sk
        JOIN customer_demographics CD ON c.c_current_cdemo_sk = CD.cd_demo_sk
    WHERE 
        ch.level < 3 AND (CD.cd_marital_status = 'M' OR CD.cd_gender = 'F')
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        DENSE_RANK() OVER (PARTITION BY CA.ca_city ORDER BY CA.ca_zip) AS address_rank
    FROM 
        customer_address ca
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) as order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY 
        ws.ws_item_sk
),
null_address AS (
    SELECT 
        c.c_customer_sk,
        MAX(CASE WHEN ca.ca_city IS NULL THEN 'Unknown' ELSE ca.ca_city END) AS city,
        MAX(CASE WHEN ca.ca_state IS NULL THEN 'Unknown' ELSE ca.ca_state END) AS state
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk
),
final_results AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.cd_gender,
        ch.cd_marital_status,
        ca.city,
        ca.state,
        sd.total_sales,
        sd.order_count,
        ROW_NUMBER() OVER (PARTITION BY ch.cd_gender ORDER BY sd.total_sales DESC) AS ranking
    FROM 
        customer_hierarchy ch
    JOIN 
        null_address ca ON ca.c_customer_sk = ch.c_customer_sk
    LEFT JOIN 
        sales_data sd ON sd.ws_item_sk = ch.c_customer_sk -- correlated subquery with bizarre match
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.city,
    fr.state,
    COALESCE(fr.total_sales, 0) AS total_sales,
    COALESCE(fr.order_count, 0) AS order_count,
    CASE
        WHEN fr.ranking IS NULL THEN 'Unranked'
        ELSE CAST(fr.ranking AS VARCHAR)
    END AS sales_ranking,
    CASE 
        WHEN fr.cd_gender IS NULL THEN 'Gender Unknown'
        ELSE fr.cd_gender
    END AS gender_description,
    CASE 
        WHEN fr.cd_marital_status = 'M' THEN 'Married'
        WHEN fr.cd_marital_status IS NULL THEN NULL
        ELSE 'Single'
    END AS marital_description
FROM 
    final_results fr
WHERE 
    (fr.total_sales IS NOT NULL OR fr.order_count IS NOT NULL)
    AND (fr.city IS NOT NULL OR fr.state IS NOT NULL)
ORDER BY 
    fr.cd_gender, 
    fr.total_sales DESC, 
    fr.order_count DESC
LIMIT 50;
