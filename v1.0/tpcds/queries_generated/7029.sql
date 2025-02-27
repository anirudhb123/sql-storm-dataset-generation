
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        MAX(ws.ws_sold_date_sk) AS last_sale_date,
        MIN(ws.ws_sold_date_sk) AS first_sale_date
    FROM web_sales ws
    JOIN date_dim dd ON dd.d_date_sk = ws.ws_sold_date_sk
    JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN warehouse w ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE dd.d_year = 2023 
    AND cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
    GROUP BY ws.web_site_id
),
RankedSales AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders,
        avg_net_profit,
        last_sale_date,
        first_sale_date,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData
)
SELECT 
    web_site_id, 
    total_sales, 
    total_orders, 
    avg_net_profit, 
    last_sale_date, 
    first_sale_date, 
    sales_rank
FROM RankedSales
WHERE sales_rank <= 10
ORDER BY total_sales DESC;
