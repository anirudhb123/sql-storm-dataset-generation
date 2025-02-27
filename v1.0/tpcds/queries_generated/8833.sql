
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(ws.ws_item_sk) AS total_items_sold,
        RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq BETWEEN 1 AND 6
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id, 
        total_sales, 
        total_orders, 
        total_items_sold
    FROM 
        RankedSales
    WHERE 
        rank <= 10
)
SELECT 
    tw.web_site_id,
    tw.total_sales,
    tw.total_orders,
    tw.total_items_sold,
    (tw.total_sales / NULLIF(tw.total_orders, 0)) AS avg_sales_per_order,
    (tw.total_items_sold / NULLIF(tw.total_orders, 0)) AS avg_items_per_order
FROM 
    TopWebSites tw
ORDER BY 
    tw.total_sales DESC;
