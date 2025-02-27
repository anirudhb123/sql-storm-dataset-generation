
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer AS c
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customers_sales_ranked AS (
    SELECT 
        rc.full_name,
        rc.ca_city,
        rc.ca_state,
        rc.cd_gender,
        rc.cd_marital_status,
        COALESCE(sd.total_sales, 0) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY COALESCE(sd.total_sales, 0) DESC) AS sales_rank
    FROM 
        ranked_customers AS rc
    LEFT JOIN 
        sales_data AS sd ON rc.c_customer_id = sd.ws_bill_customer_sk
)
SELECT 
    csr.full_name,
    csr.ca_city,
    csr.ca_state,
    csr.cd_gender,
    csr.cd_marital_status,
    csr.total_sales,
    csr.sales_rank
FROM 
    customers_sales_ranked AS csr
WHERE 
    csr.city_rank <= 5 AND csr.sales_rank <= 10
ORDER BY 
    csr.ca_city, csr.total_sales DESC;
