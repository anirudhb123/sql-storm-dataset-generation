
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown'
            ELSE ib.ib_lower_bound || '-' || ib.ib_upper_bound
        END AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state,
        si.total_sales,
        si.order_count
    FROM 
        customer_info ci
    JOIN 
        sales_data si ON ci.c_customer_sk = si.ws_bill_customer_sk
    WHERE 
        si.rnk <= 10
),
sales_comparison AS (
    SELECT 
        a.c_customer_id AS customer_id_a,
        b.c_customer_id AS customer_id_b,
        a.total_sales - b.total_sales AS sales_difference
    FROM 
        (SELECT 
            c_customer_id, total_sales 
         FROM 
            top_customers 
         WHERE 
            cd_gender = 'F') a
    FULL OUTER JOIN 
        (SELECT 
            c_customer_id, total_sales 
         FROM 
            top_customers 
         WHERE 
            cd_gender = 'M') b ON a.c_customer_id = b.c_customer_id
)
SELECT 
    sales_a.customer_id_a,
    sales_a.sales_difference,
    COALESCE(sales_b.customer_id_b, 'N/A') AS customer_id_b,
    sales_b.total_sales AS total_sales_b
FROM 
    sales_comparison sales_a
LEFT JOIN 
    top_customers sales_b ON sales_a.customer_id_b = sales_b.c_customer_id
WHERE 
    sales_a.sales_difference != 0;
