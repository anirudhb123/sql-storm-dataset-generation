
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS number_of_orders,
        AVG(ws.ws_net_profit) AS average_profit,
        SUM(CASE WHEN c.c_gender = 'F' THEN ws.ws_quantity ELSE 0 END) AS female_sales,
        SUM(CASE WHEN c.c_gender = 'M' THEN ws.ws_quantity ELSE 0 END) AS male_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id, ws.web_name
), 
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
), 
RankedSales AS (
    SELECT 
        s.web_site_id,
        s.total_sales,
        s.number_of_orders,
        s.average_profit,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SalesSummary s
)
SELECT 
    rs.web_site_id,
    rs.total_sales,
    rs.number_of_orders,
    rs.average_profit,
    ws.total_net_profit,
    CASE 
        WHEN rs.sales_rank <= 5 THEN 'Top Performer' 
        ELSE 'Regular Performer' 
    END AS performance_category
FROM 
    RankedSales rs
JOIN 
    WarehouseSales ws ON rs.web_site_id = ws.w_warehouse_id
WHERE 
    ws.total_net_profit IS NOT NULL
ORDER BY 
    rs.total_sales DESC;
