
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk
),
AggregatedData AS (
    SELECT 
        ca.city,
        ca.state,
        COUNT(DISTINCT cd.c_customer_id) AS customer_count,
        AVG(cd.total_spent) AS avg_spent,
        AVG(cd.total_orders) AS avg_orders_per_customer,
        COUNT(DISTINCT (CASE WHEN cd.cd_gender = 'M' THEN cd.c_customer_id END)) AS male_count,
        COUNT(DISTINCT (CASE WHEN cd.cd_gender = 'F' THEN cd.c_customer_id END)) AS female_count,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count
    FROM 
        CustomerData cd
    GROUP BY 
        cd.ca_city, 
        cd.ca_state
)
SELECT 
    ca.city,
    ca.state,
    customer_count,
    avg_spent,
    avg_orders_per_customer,
    male_count,
    female_count,
    married_count,
    CONCAT(male_count, ' Male, ', female_count, ' Female') AS gender_distribution,
    CASE 
        WHEN avg_spent > 1000 THEN 'High Spenders'
        WHEN avg_spent BETWEEN 500 AND 1000 THEN 'Medium Spenders'
        ELSE 'Low Spenders'
    END AS spending_category
FROM 
    AggregatedData ca
ORDER BY 
    customer_count DESC,
    avg_spent DESC;
