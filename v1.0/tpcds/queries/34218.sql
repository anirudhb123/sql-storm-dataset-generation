
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) as price_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_country = 'USA'
        AND ws.ws_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
grouped_sales AS (
    SELECT 
        sd.ws_order_number,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        MAX(sd.price_rank) AS max_price_order_rank
    FROM 
        sales_data sd
    GROUP BY 
        sd.ws_order_number
)
SELECT 
    g.ws_order_number,
    g.total_quantity,
    g.total_sales,
    g.max_price_order_rank,
    CASE 
        WHEN g.total_sales IS NULL THEN 'No Sales'
        WHEN g.total_sales < 100 THEN 'Low Sales'
        WHEN g.total_sales BETWEEN 100 AND 500 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category,
    COALESCE(addr.ca_city, 'Unknown') AS customer_city,
    CASE 
        WHEN EXISTS (SELECT 1 FROM store_returns sr WHERE sr.sr_ticket_number = g.ws_order_number) THEN 'Returned'
        ELSE 'Completed'
    END AS order_status
FROM 
    grouped_sales g
LEFT JOIN 
    customer c ON c.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_order_number = g.ws_order_number LIMIT 1)
LEFT JOIN 
    customer_address addr ON c.c_current_addr_sk = addr.ca_address_sk
ORDER BY 
    g.total_sales DESC;
