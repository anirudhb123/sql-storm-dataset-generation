
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(ws.ws_item_sk) AS item_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND dd.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        ws.web_site_id
),
top_websites AS (
    SELECT 
        web_site_id,
        total_sales,
        order_count,
        item_count
    FROM 
        ranked_sales
    WHERE 
        rank <= 10
)
SELECT 
    tw.web_site_id,
    tw.total_sales,
    tw.order_count,
    tw.item_count,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state
FROM 
    top_websites tw
JOIN 
    web_site ws ON tw.web_site_id = ws.web_site_id
JOIN 
    web_returns wr ON wr.wr_web_page_sk = ws.web_site_sk
JOIN 
    customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    wr.wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
ORDER BY 
    tw.total_sales DESC;
