
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_id, ca.ca_city
),
FilteredSales AS (
    SELECT 
        fs.c_customer_id,
        fs.ca_city,
        fs.total_sales
    FROM 
        RankedSales fs
    WHERE 
        fs.sales_rank <= 5
),
SalesWithPromo AS (
    SELECT 
        fs.c_customer_id,
        fs.ca_city,
        (fs.total_sales - COALESCE(p.p_discount_active, 0)) AS adjusted_sales
    FROM 
        FilteredSales fs
    LEFT JOIN 
        promotion p ON p.p_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = fs.c_customer_id)
)
SELECT 
    s.ca_city,
    COUNT(s.c_customer_id) AS customer_count,
    AVG(s.adjusted_sales) AS avg_sales,
    MAX(s.adjusted_sales) AS max_sales,
    STRING_AGG(CASE WHEN s.adjusted_sales IS NULL THEN 'No Sales' ELSE s.c_customer_id END, ', ') AS customer_ids
FROM 
    SalesWithPromo s
GROUP BY 
    s.ca_city
HAVING 
    MAX(s.adjusted_sales) > (SELECT AVG(total_sales) FROM FilteredSales)
ORDER BY 
    customer_count DESC;
