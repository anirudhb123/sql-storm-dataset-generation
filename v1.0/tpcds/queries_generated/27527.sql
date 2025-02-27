
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.d_date AS first_purchase_date,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        COUNT(wr.wr_order_number) AS total_web_returns
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        d.d_date, 
        cd.cd_marital_status, 
        cd.cd_gender, 
        cd.cd_education_status, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_zip
),
return_analysis AS (
    SELECT 
        full_name,
        first_purchase_date,
        cd_marital_status,
        cd_gender,
        cd_education_status,
        ca_city,
        ca_state,
        ca_zip,
        CASE 
            WHEN total_web_returns > 0 THEN 'Frequent Returner'
            ELSE 'Rare Returner'
        END AS return_behavior
    FROM customer_info
)
SELECT 
    return_behavior,
    COUNT(*) AS customer_count,
    AVG(DATEDIFF(CURRENT_DATE, first_purchase_date)) AS avg_days_since_first_purchase
FROM return_analysis
GROUP BY return_behavior
ORDER BY customer_count DESC;
