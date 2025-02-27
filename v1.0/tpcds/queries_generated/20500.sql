
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(NULLIF(cd.cd_purchase_estimate, 0), 999999) AS purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name) as gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_data AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
ranked_sales AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        s.total_orders,
        s.total_sales,
        s.total_discount,
        ROW_NUMBER() OVER (PARTITION BY ci.cd_gender ORDER BY s.total_sales DESC) AS sales_gender_rank
    FROM 
        customer_info ci
    JOIN 
        sales_data s ON ci.c_customer_sk = s.ws_bill_customer_sk
),
final_output AS (
    SELECT 
        sk.c_customer_sk,
        sk.c_first_name,
        sk.c_last_name,
        COALESCE(sk.cd_gender, 'Unknown') AS cd_gender,
        sk.total_orders,
        sk.total_sales,
        sk.total_discount,
        CASE 
            WHEN sk.total_sales IS NULL THEN 'No Sales'
            WHEN sk.sales_gender_rank = 1 THEN 'Top Seller'
            ELSE 'Regular Customer'
        END AS customer_category
    FROM 
        ranked_sales sk
    WHERE 
        sk.total_orders > (SELECT AVG(total_orders) FROM sales_data)
    ORDER BY 
        sk.total_sales DESC
)
SELECT 
    f.c_customer_sk,
    f.c_first_name || ' ' || f.c_last_name AS full_name,
    f.cd_gender,
    f.total_orders,
    ROUND(f.total_sales, 2) AS total_sales,
    ROUND(f.total_discount, 2) AS total_discount,
    f.customer_category,
    CONCAT('Sales rank: ', f.sales_gender_rank, ' | Gender rank: ', f.gender_rank) AS rankings_info
FROM 
    final_output f
WHERE 
    f.cd_gender IN ('M', 'F')
    AND (f.total_orders IS NOT NULL OR f.total_discount IS NOT NULL)
    AND NOT EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_customer_sk = f.c_customer_sk AND c.c_birth_year IS NULL
    )
ORDER BY 
    f.total_sales DESC
LIMIT 100 OFFSET 10;
