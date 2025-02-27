
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MIN(ws.ws_sold_date_sk) AS first_purchase,
        MAX(ws.ws_sold_date_sk) AS last_purchase
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
sales_summary AS (
    SELECT 
        total_sales,
        order_count,
        DATEDIFF(DAY, first_purchase, last_purchase) AS purchase_duration,
        CASE 
            WHEN SUM(total_sales) > 10000 THEN 'High Value'
            WHEN SUM(total_sales) BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM 
        customer_sales
    GROUP BY 
        total_sales, order_count, first_purchase, last_purchase
),
best_customers AS (
    SELECT 
        total_sales,
        order_count,
        value_category,
        ROW_NUMBER() OVER (PARTITION BY value_category ORDER BY total_sales DESC) AS rn
    FROM 
        sales_summary
)
SELECT 
    b.value_category,
    b.total_sales,
    b.order_count,
    b.rn,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    best_customers b
JOIN 
    customer c ON b.total_sales = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    b.rn <= 10
ORDER BY 
    b.value_category, b.total_sales DESC;
