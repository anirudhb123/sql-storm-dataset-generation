
WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
categorized_sales AS (
    SELECT
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_sales,
        s.total_orders,
        CASE 
            WHEN s.total_sales IS NULL THEN 'No Sales'
            WHEN s.total_sales < 100 THEN 'Low Sales'
            WHEN s.total_sales BETWEEN 100 AND 500 THEN 'Medium Sales'
            ELSE 'High Sales' 
        END AS sales_category
    FROM 
        sales_summary s
),
high_value_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.sales_category
    FROM
        categorized_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_category = 'High Sales' AND cs.total_orders > 2
)
SELECT 
    hvc.c_customer_sk,
    CONCAT(hvc.c_first_name, ' ', hvc.c_last_name) AS full_name,
    hvc.total_sales,
    hvc.sales_category,
    COALESCE((
        SELECT 
            AVG(ws_ext_sales_price)
        FROM 
            web_sales
        WHERE 
            ws_bill_customer_sk = hvc.c_customer_sk
        AND 
            ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1)
    ), 0) AS avg_sales_last_year,
    (
        SELECT 
            COUNT(DISTINCT wr_order_number)
        FROM 
            web_returns wr
        WHERE 
            wr_returning_customer_sk = hvc.c_customer_sk
    ) AS total_returns,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders_this_year
FROM 
    high_value_customers hvc
JOIN 
    web_sales ws ON hvc.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_current_year = 'Y')
GROUP BY 
    hvc.c_customer_sk, hvc.c_first_name, hvc.c_last_name, hvc.total_sales, hvc.sales_category
ORDER BY 
    hvc.total_sales DESC
LIMIT 100;
