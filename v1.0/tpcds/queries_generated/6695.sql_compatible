
WITH SalesData AS (
    SELECT 
        ws.web_site_id, 
        c.c_customer_id, 
        SUM(ws.ws_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_ship_mode_sk) AS shipping_methods_used
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        d.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id, 
        c.c_customer_id
),
RankedSales AS (
    SELECT 
        web_site_id, 
        c_customer_id, 
        total_sales, 
        order_count, 
        avg_net_profit, 
        shipping_methods_used,
        RANK() OVER (PARTITION BY web_site_id ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    r.web_site_id,
    r.c_customer_id,
    r.total_sales,
    r.order_count,
    r.avg_net_profit,
    r.shipping_methods_used,
    a.ca_country
FROM 
    RankedSales r
JOIN 
    customer_address a ON r.c_customer_id = a.ca_address_id
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.web_site_id, 
    r.total_sales DESC;
