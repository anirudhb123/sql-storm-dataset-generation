
WITH demography AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN c.c_birth_year BETWEEN 1980 AND 1995 THEN 1 ELSE 0 END) AS millennial_count
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status, cd_education_status
),
location_summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        STRING_AGG(ca_city, ', ') AS cities
    FROM 
        customer_address AS ca
    JOIN 
        customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_state
),
sales_summary AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS orders_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_addr_sk
),
final_report AS (
    SELECT 
        d.cd_gender, 
        d.cd_marital_status,
        d.cd_education_status,
        lm.ca_state,
        lm.customer_count AS state_customer_count,
        lm.cities,
        COALESCE(ss.total_sales, 0) AS state_sales,
        COALESCE(ss.orders_count, 0) AS state_orders,
        d.customer_count AS total_customers,
        d.millennial_count
    FROM 
        demography AS d
    LEFT JOIN 
        location_summary AS lm ON d.customer_count > 0
    LEFT JOIN 
        sales_summary AS ss ON lm.customer_count > 0
)
SELECT 
    cd_gender, 
    cd_marital_status, 
    cd_education_status, 
    ca_state, 
    state_customer_count, 
    cities, 
    state_sales, 
    state_orders, 
    total_customers, 
    millennial_count
FROM 
    final_report
WHERE 
    total_customers > 100
ORDER BY 
    state_sales DESC, 
    total_customers DESC;
