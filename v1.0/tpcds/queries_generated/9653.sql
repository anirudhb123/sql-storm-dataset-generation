
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit,
        SUM(ws.ws_ext_tax) AS total_tax,
        DATE(d.d_date) AS sales_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store s ON c.c_current_addr_sk = s.s_store_sk
    WHERE
        d.d_year = 2023 
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id, sales_date
),
SalesRanked AS (
    SELECT 
        web_site_id,
        total_sales,
        order_count,
        avg_profit,
        total_tax,
        sales_date,
        RANK() OVER (PARTITION BY sales_date ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    web_site_id,
    SUM(total_sales) AS cumulative_sales,
    SUM(order_count) AS total_orders,
    AVG(avg_profit) AS avg_daily_profit,
    SUM(total_tax) AS total_collected_tax
FROM 
    SalesRanked
WHERE 
    sales_rank <= 10
GROUP BY 
    web_site_id
ORDER BY 
    cumulative_sales DESC;
