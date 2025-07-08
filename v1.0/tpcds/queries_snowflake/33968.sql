
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) as rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
RecentSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    GROUP BY 
        ws_item_sk
),
FilteredSales AS (
    SELECT 
        s.ws_item_sk,
        s.total_sales,
        r.total_revenue,
        CASE 
            WHEN r.total_revenue IS NULL THEN 'No Revenue'
            ELSE 'Has Revenue'
        END AS revenue_status
    FROM 
        SalesCTE s
    LEFT JOIN 
        RecentSales r ON s.ws_item_sk = r.ws_item_sk
    WHERE 
        s.rank <= 10
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    fs.total_sales,
    fs.total_revenue,
    fs.revenue_status,
    ca.ca_city, 
    ca.ca_state
FROM 
    FilteredSales fs
JOIN 
    item i ON fs.ws_item_sk = i.i_item_sk
JOIN 
    customer c ON c.c_customer_sk = (
        SELECT sc.ss_customer_sk 
        FROM store_sales sc 
        WHERE sc.ss_item_sk = fs.ws_item_sk 
        ORDER BY sc.ss_sold_date_sk DESC 
        LIMIT 1)
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_state IS NOT NULL
ORDER BY 
    fs.total_sales DESC
LIMIT 50;
