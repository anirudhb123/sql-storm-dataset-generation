
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
), customer_details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN LOWER(cd.cd_gender) = 'f' THEN 'Female'
            WHEN LOWER(cd.cd_gender) = 'm' THEN 'Male'
            ELSE 'Not Specified'
        END AS gender_description
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), top_customers AS (
    SELECT 
        rs.ws_bill_customer_sk,
        cd.c_customer_id,
        cd.gender_description,
        cd.ca_city,
        cd.ca_state
    FROM 
        ranked_sales rs
    JOIN 
        customer_details cd ON rs.ws_bill_customer_sk = cd.c_customer_id
    WHERE 
        profit_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.gender_description,
    tc.ca_city,
    COUNT(*) AS number_of_purchases,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
    STRING_AGG(CONCAT(DISTINCT 'Sold: ', CAST(ws.ws_ext_list_price AS VARCHAR), ' for ', CAST(ws.ws_net_paid AS VARCHAR)), '; ') AS purchase_details
FROM 
    top_customers tc
LEFT JOIN 
    web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
GROUP BY 
    tc.c_customer_id, tc.gender_description, tc.ca_city
HAVING 
    COUNT(*) > 1
ORDER BY 
    total_net_profit DESC NULLS LAST
LIMIT 5;
