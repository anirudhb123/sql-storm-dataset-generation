
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        customer_sales cs
    JOIN 
        customer_demographics c ON cs.c_customer_sk = c.cd_demo_sk
    WHERE 
        cs.sales_rank <= 5
),
sales_with_address AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        tc.total_sales,
        ca.ca_city,
        ca.ca_state
    FROM 
        top_customers tc
    LEFT JOIN 
        customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ca.ca_state,
        SUM(total_sales) AS total_sales_by_state,
        COUNT(DISTINCT c_first_name || ' ' || c_last_name) AS unique_customers,
        CASE 
            WHEN SUM(total_sales) IS NULL THEN 'No Sales'
            ELSE 'Sales Exist'
        END AS sales_status
    FROM 
        sales_with_address sa
    GROUP BY 
        ca.ca_state
)
SELECT 
    sb.ca_state,
    sb.total_sales_by_state,
    sb.unique_customers,
    sb.sales_status
FROM 
    sales_summary sb
WHERE 
    sb.sales_status = 'Sales Exist'
ORDER BY 
    sb.total_sales_by_state DESC
LIMIT 10;
