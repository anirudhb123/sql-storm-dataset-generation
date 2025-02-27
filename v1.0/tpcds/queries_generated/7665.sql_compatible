
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
        AND cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_id
), TopSales AS (
    SELECT 
        web_site_id, 
        total_sales, 
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    ts.web_site_id,
    ts.total_sales,
    ts.order_count,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    w.w_country,
    AVG(ss.ss_net_profit) AS avg_net_profit
FROM 
    TopSales ts
JOIN 
    store_sales ss ON ts.web_site_id = ss.ss_store_sk
JOIN 
    warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
GROUP BY 
    ts.web_site_id, ts.total_sales, ts.order_count, w.w_warehouse_name, w.w_city, w.w_state, w.w_country
ORDER BY 
    ts.total_sales DESC;
