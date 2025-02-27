
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_month IS NOT NULL AND 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_id, ws.ws_sold_date_sk
),
TopSales AS (
    SELECT 
        web_site_id,
        total_sales
    FROM 
        RankedSales 
    WHERE 
        sales_rank <= 3
)
SELECT 
    t.web_site_id,
    t.total_sales,
    COALESCE(t.total_sales - (SELECT AVG(total_sales) FROM TopSales) OVER(), 0) AS sales_variation,
    CASE 
        WHEN t.total_sales > (SELECT AVG(total_sales) FROM TopSales)
        THEN 'Above Average'
        WHEN t.total_sales < (SELECT AVG(total_sales) FROM TopSales)
        THEN 'Below Average'
        ELSE 'Average'
    END AS sales_performance,
    ad.ca_city,
    CASE 
        WHEN ad.ca_state IS NULL THEN 'Unknown State'
        ELSE ad.ca_state
    END as state_info
FROM 
    TopSales t
LEFT OUTER JOIN 
    customer_address ad ON ad.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = (SELECT TOP 1 ws_bill_customer_sk FROM web_sales WHERE ws_web_page_sk = t.web_site_id ORDER BY ws_sold_date_sk DESC))
WHERE 
    ad.ca_country = 'USA' OR ad.ca_country IS NULL
ORDER BY 
    t.total_sales DESC, 
    state_info DESC;
