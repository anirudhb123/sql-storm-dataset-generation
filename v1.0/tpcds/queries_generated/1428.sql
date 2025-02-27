
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c_customer_id,
        ss.total_sales,
        ss.order_count
    FROM 
        customer c
    JOIN 
        sales_summary ss ON c.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ss.sales_rank <= 10
),
customer_address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country
),
average_sales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM 
        sales_summary
),
sales_distribution AS (
    SELECT 
        CASE 
            WHEN total_sales < 1000 THEN 'Low'
            WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS sales_band,
        COUNT(*) AS customer_count
    FROM 
        top_customers
    GROUP BY 
        sales_band
)
SELECT 
    c.customer_id,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    COALESCE(sd.customer_count, 0) AS distribution_count,
    avg.avg_sales,
    CASE 
        WHEN total_sales > avg.avg_sales THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_comparison
FROM 
    top_customers c
JOIN 
    customer_address_info ca ON c.c_customer_id = ca.ca_address_sk
CROSS JOIN 
    average_sales avg
LEFT JOIN 
    sales_distribution sd ON c.total_sales >= CASE 
        WHEN sd.sales_band = 'Low' THEN 0
        WHEN sd.sales_band = 'Medium' THEN 1000
        ELSE 5000
    END
ORDER BY 
    c.total_sales DESC;
