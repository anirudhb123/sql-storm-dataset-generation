
WITH ranked_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_current_cdemo_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name
    FROM 
        ranked_sales r
    WHERE 
        r.sales_rank <= 5
),
sales_by_year AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    sb.total_sales,
    CASE 
        WHEN sb.total_sales IS NULL THEN 'No Sales Recorded'
        ELSE 'Sales Recorded'
    END AS sales_status,
    d.d_year,
    SUM(sb.total_sales) OVER (PARTITION BY d.d_year) AS total_sales_by_year
FROM 
    top_customers tc
LEFT JOIN 
    sales_by_year sb ON sb.total_sales IS NOT NULL
FULL OUTER JOIN 
    date_dim d ON d.d_year = (SELECT MAX(d_year) FROM sales_by_year).
WHERE 
    d.d_current_year = 'Y'
ORDER BY 
    total_sales DESC NULLS LAST;
