
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        c.c_email_address,
        CASE 
            WHEN cd.cd_purchase_estimate < 500 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1500 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estim_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ExtendedInfo AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.purchase_estim_category,
        COUNT(ws.ws_order_number) AS total_purchases,
        SUM(ws.ws_sales_price) AS total_spent,
        MAX(CONCAT(DATE_FORMAT(d.d_date, '%Y-%m-%d'), ' ', t.t_hour, ':', LPAD(t.t_minute, 2, '0'))) AS last_purchase_time
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN 
        time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    GROUP BY 
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.purchase_estim_category
)
SELECT 
    *,
    CASE 
        WHEN total_spent < 1000 THEN 'Infrequent Buyer'
        WHEN total_spent BETWEEN 1000 AND 5000 THEN 'Regular Buyer'
        ELSE 'Frequent Buyer'
    END AS buyer_category
FROM 
    ExtendedInfo
WHERE 
    cd_gender = 'F' AND 
    total_purchases > 5
ORDER BY 
    total_spent DESC
LIMIT 100;
