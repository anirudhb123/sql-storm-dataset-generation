
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
Benchmark AS (
    SELECT
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        si.total_sales,
        si.orders_count,
        CASE 
            WHEN si.total_sales IS NULL THEN 'No Sales'
            WHEN si.total_sales > 1000 THEN 'High Value'
            WHEN si.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS sales_category
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    sales_category,
    COUNT(*) AS customer_count,
    AVG(total_sales) AS avg_sales,
    MAX(total_sales) AS max_sales,
    MIN(total_sales) AS min_sales
FROM 
    Benchmark
GROUP BY 
    sales_category
ORDER BY 
    sales_category;
