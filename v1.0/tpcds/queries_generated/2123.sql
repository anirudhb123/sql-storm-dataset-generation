
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.bill_addr_sk,
        ws.item_sk,
        ws.order_number,
        SUM(ws.quantity) AS total_quantity,
        SUM(ws.ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
    GROUP BY 
        ws.bill_customer_sk, ws.bill_addr_sk, ws.item_sk, ws.order_number
),
high_value_customers AS (
    SELECT 
        cd.gender,
        cd.marital_status,
        COUNT(DISTINCT cs.order_number) AS total_orders,
        SUM(cs.total_sales) AS total_spent
    FROM 
        customer_demographics cd
    JOIN 
        (SELECT 
            bill_customer_sk, 
            item_sk, 
            SUM(total_sales) AS total_sales
         FROM 
            ranked_sales 
         WHERE 
            sales_rank <= 5 
         GROUP BY 
            bill_customer_sk, item_sk) cs ON cd.cd_demo_sk = cs.bill_customer_sk
    GROUP BY 
        cd.gender, cd.marital_status
),
final_results AS (
    SELECT 
        hvc.gender,
        hvc.marital_status,
        hvc.total_orders,
        hvc.total_spent,
        COUNT(DISTINCT ca.ca_address_sk) AS total_addresses,
        COUNT(DISTINCT ws.web_page_sk) AS total_web_pages
    FROM 
        high_value_customers hvc
    LEFT JOIN 
        customer_address ca ON hvc.bill_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON ws.bill_customer_sk = hvc.bill_customer_sk
    GROUP BY 
        hvc.gender, hvc.marital_status, hvc.total_orders, hvc.total_spent
)
SELECT 
    gender,
    marital_status,
    total_orders,
    total_spent,
    total_addresses,
    total_web_pages
FROM 
    final_results
WHERE 
    total_orders > 10
    AND total_spent > 1000
ORDER BY 
    total_spent DESC;
