
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
top_sales AS (
    SELECT 
        web_site_sk,
        web_name,
        total_sales,
        total_quantity
    FROM 
        sales_data
    WHERE 
        sales_rank <= 5
),
customer_with_returns AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT sr.sr_item_sk) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
final_summary AS (
    SELECT 
        ts.web_name,
        ts.total_sales,
        ts.total_quantity,
        COALESCE(cwr.return_count, 0) AS return_count,
        COALESCE(cwr.total_return_amount, 0) AS total_return_amount,
        (ts.total_sales - COALESCE(cwr.total_return_amount, 0)) AS net_sales
    FROM 
        top_sales ts
    LEFT JOIN 
        customer_with_returns cwr ON ts.web_site_sk = cwr.c_customer_sk
)
SELECT 
    fs.web_name,
    fs.total_sales,
    fs.total_quantity,
    fs.return_count,
    fs.total_return_amount,
    fs.net_sales,
    CASE 
        WHEN fs.net_sales > 1000 THEN 'High Sales'
        WHEN fs.net_sales BETWEEN 500 AND 1000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    final_summary fs
ORDER BY 
    fs.total_sales DESC;
