
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023 
        AND cd.cd_gender = 'F'
        AND i.i_current_price > 20.00 
    GROUP BY 
        ws.web_site_id, d.d_year
),
performance_benchmark AS (
    SELECT 
        web_site_id,
        d_year,
        total_sales,
        total_orders,
        total_profit,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    web_site_id,
    d_year,
    total_sales,
    total_orders,
    total_profit,
    sales_rank
FROM 
    performance_benchmark
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, total_sales DESC;
