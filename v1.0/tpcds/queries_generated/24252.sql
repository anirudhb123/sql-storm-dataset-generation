
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws_ext_sales_price IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        sr_reason_sk
    FROM 
        store_returns 
    GROUP BY 
        sr_returned_date_sk, sr_return_time_sk, sr_reason_sk
)
SELECT 
    d.d_date AS sales_date,
    c.c_first_name || ' ' || c.c_last_name AS customer_full_name,
    COALESCE(COUNT(DISTINCT ws.ws_order_number), 0) AS total_orders,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
    COALESCE(SUM(cr.total_return_amount), 0) AS total_returns,
    (SUM(ws.ws_ext_sales_price) - COALESCE(SUM(cr.total_return_amount), 0)) AS net_sales,
    AVG(ws.ws_ext_sales_price) FILTER (WHERE ws.ws_ext_sales_price > 100) AS avg_high_value_sales,
    MAX(ws.ws_ext_sales_price) AS max_sale,
    CASE 
        WHEN c.c_birth_month IS NULL THEN 'Unknown Month'
        ELSE d.d_month_seq
    END AS birth_month_indicator
FROM 
    customer c 
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    CustomerReturns cr ON cr.sr_returned_date_sk = ws.ws_sold_date_sk
JOIN 
    date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
WHERE 
    (d.d_date BETWEEN '2023-01-01' AND '2023-12-31')
    AND (d.d_dow IN (1, 2, 3) OR c.c_birth_year IS NOT NULL)
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_birth_day IS NOT NULL)
GROUP BY 
    d.d_date, c.c_first_name, c.c_last_name, c.c_birth_month
HAVING 
    SUM(ws.ws_ext_sales_price) > 1000 OR COUNT(DISTINCT ws.ws_order_number) > 10
ORDER BY 
    total_sales DESC
LIMIT 50;
