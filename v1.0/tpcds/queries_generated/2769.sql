
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
TopWebSites AS (
    SELECT 
        web_site_sk, 
        web_name 
    FROM 
        RankedSales 
    WHERE 
        sales_rank <= 10
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_net_paid_inc_tax) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS number_of_orders,
    MAX(dd.d_date) AS last_purchase_date
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
WHERE 
    c.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales)
    AND (ca.ca_state IS NOT NULL OR ca.ca_city IS NOT NULL)
    AND ws.ws_web_site_sk IN (SELECT web_site_sk FROM TopWebSites)
GROUP BY 
    c.c_customer_id, ca.ca_city, ca.ca_state
HAVING 
    total_spent > (SELECT AVG(total_spent) FROM (
        SELECT 
            SUM(ws2.ws_net_paid_inc_tax) AS total_spent
        FROM 
            web_sales ws2
        GROUP BY 
            ws2.ws_bill_customer_sk
    ) AS avg_spent)
ORDER BY 
    total_spent DESC;
