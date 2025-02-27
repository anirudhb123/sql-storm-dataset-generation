
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        rank() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) as sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
top_sales AS (
    SELECT 
        ws_item_sk,
        total_sales
    FROM 
        sales_data
    WHERE 
        sales_rank <= 5
),
customer_analysis AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS unique_customers,
        SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_state
),
final_report AS (
    SELECT 
        ca.ca_state,
        ta.total_sales,
        ca.unique_customers,
        ca.male_customers,
        ca.female_customers,
        COALESCE(CAST(NULLIF(ca.unique_customers, 0) AS FLOAT) / NULLIF(ta.total_sales, 0), 0) AS customer_sales_ratio
    FROM 
        customer_analysis AS ca
    LEFT JOIN 
        (SELECT 
            ca_state,
            SUM(total_sales) AS total_sales
         FROM 
            top_sales 
         JOIN 
            customer_address AS ca ON ca.ca_address_sk IN (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_current_addr_sk IS NOT NULL)
         GROUP BY 
            ca_state) AS ta ON ca.ca_state = ta.ca_state
)
SELECT 
    *,
    CASE 
        WHEN customer_sales_ratio < 0.01 THEN 'Low Performer'
        WHEN customer_sales_ratio BETWEEN 0.01 AND 0.1 THEN 'Average Performer'
        ELSE 'High Performer' 
    END AS performance_category
FROM 
    final_report
ORDER BY 
    ca_state;
