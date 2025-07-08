
WITH RECURSIVE address_hierarchy AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_address_sk) AS addr_rank
    FROM 
        customer_address
    WHERE 
        ca_country IS NOT NULL
),
sales_metrics AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_data AS (
    SELECT 
        c_customer_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COUNT(DISTINCT CASE WHEN cd_marital_status = 'M' THEN c_customer_sk END) AS married_count,
        SUM(COALESCE(cd_purchase_estimate, 0)) AS total_estimated_purchases
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c_customer_sk, cd_gender
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.ca_country,
    SUM(sm.total_quantity) AS total_quantity_sold,
    SUM(sm.total_sales) AS total_sales_value,
    MAX(cd.total_estimated_purchases) AS max_estimated_purchases,
    COUNT(DISTINCT cd.c_customer_sk) AS unique_customers,
    LISTAGG(DISTINCT cd.gender, ', ') WITHIN GROUP (ORDER BY cd.gender) AS gender_distribution
FROM 
    address_hierarchy a
LEFT JOIN 
    sales_metrics sm ON sm.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_item_desc LIKE '%gadget%')
LEFT JOIN 
    customer_data cd ON cd.c_customer_sk = (
        SELECT 
            c_customer_sk 
        FROM 
            customer 
        WHERE 
            c_current_addr_sk = a.ca_address_sk 
        LIMIT 1
    ) 
WHERE 
    a.addr_rank <= 10
GROUP BY 
    a.ca_city, a.ca_state, a.ca_country
HAVING 
    COUNT(DISTINCT cd.c_customer_sk) > 5 
ORDER BY 
    total_sales_value DESC NULLS LAST;
