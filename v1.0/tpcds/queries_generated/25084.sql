
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            WHEN cd.cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        ca.ca_city,
        ca.ca_state,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        household_demographics AS hd ON c.c_customer_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, full_name, cd.cd_gender, ca.ca_city, ca.ca_state, hd.hd_income_band_sk, hd.hd_buy_potential
),
AggregatedData AS (
    SELECT 
        city,
        state,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(total_spent) AS avg_spent,
        SUM(total_orders) AS total_orders
    FROM (
        SELECT 
            ca.ca_city AS city,
            ca.ca_state AS state,
            c_customer_sk,
            total_orders,
            total_spent
        FROM 
            CustomerData
    ) AS customer_summary
    GROUP BY 
        city, state
)
SELECT 
    city,
    state,
    customer_count,
    avg_spent,
    total_orders,
    RANK() OVER (ORDER BY avg_spent DESC) AS city_rank
FROM 
    AggregatedData
WHERE 
    customer_count > 10
ORDER BY 
    avg_spent DESC;
