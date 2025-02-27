
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as gender_rank,
        COALESCE(NULLIF(cd.cd_credit_rating, ''), 'Unknown') AS normalized_credit_rating
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    WHERE 
        c.c_birth_year < 2000
),
recent_sales AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        MAX(ws_ship_date_sk) AS last_purchase_date
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim WHERE d_current_day = 'Y')
    GROUP BY 
        ws_bill_customer_sk
),
high_value_customers AS (
    SELECT
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.normalized_credit_rating,
        rs.total_sales,
        rs.order_count,
        DENSE_RANK() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
    FROM 
        customer_info AS ci
    JOIN 
        recent_sales AS rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        rs.total_sales > (
            SELECT AVG(total_sales) FROM recent_sales
        )
)
SELECT 
    hvc.c_customer_sk,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.normalized_credit_rating,
    hvc.total_sales,
    hvc.order_count,
    COALESCE(NULLIF(hvc.normalized_credit_rating, 'Unknown'), CAST(NULL AS VARCHAR)) AS credit_rating_output,
    CASE 
        WHEN hvc.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category,
    COUNT(DISTINCT CASE WHEN rs.last_purchase_date > (SELECT MAX(d_date_sk) - 90 FROM date_dim) THEN rs.ws_bill_customer_sk END) OVER () AS active_customers_last_90_days
FROM 
    high_value_customers AS hvc
LEFT JOIN 
    recent_sales AS rs ON hvc.c_customer_sk = rs.ws_bill_customer_sk
WHERE 
    hvc.sales_rank BETWEEN 1 AND 100
ORDER BY 
    hvc.total_sales DESC;
