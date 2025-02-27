
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_paid) AS avg_sale_price,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        ca.ca_state = 'CA'
    GROUP BY 
        ws.web_site_id
), 
TopSales AS (
    SELECT 
        web_site_id,
        total_quantity,
        total_sales,
        avg_sale_price,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    t.web_site_id,
    t.total_quantity,
    t.total_sales,
    t.avg_sale_price,
    t.total_orders
FROM 
    TopSales t
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
