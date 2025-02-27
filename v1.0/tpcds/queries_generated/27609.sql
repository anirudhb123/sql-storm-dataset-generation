
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IN ('NY', 'CA', 'TX')
    GROUP BY 
        ws.web_site_id
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_quantity,
        total_sales,
        total_orders
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    tw.web_site_id,
    tw.total_quantity,
    tw.total_sales,
    tw.total_orders,
    CONCAT('Website ', tw.web_site_id, 
           ' has a total sales of $', ROUND(tw.total_sales, 2), 
           ' from ', tw.total_quantity, ' items sold, across ', tw.total_orders, ' orders.') AS sales_summary
FROM 
    TopWebsites tw
ORDER BY 
    tw.total_sales DESC;
