
WITH sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 
        AND cd.cd_gender = 'F'
    GROUP BY 
        ws.ws_sold_date_sk
),
daily_avg AS (
    SELECT 
        ss.ws_sold_date_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.total_orders,
        ss.avg_profit,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank,
        AVG(ss.total_sales) OVER () AS avg_sales
    FROM 
        sales_summary ss
)
SELECT 
    dd.d_date AS sale_date,
    da.total_quantity,
    da.total_sales,
    da total_orders,
    da.avg_profit,
    da.sales_rank,
    da.avg_sales
FROM 
    daily_avg da
JOIN 
    date_dim dd ON da.ws_sold_date_sk = dd.d_date_sk
WHERE 
    da.total_sales > da.avg_sales
ORDER BY 
    da.total_sales DESC
LIMIT 100;
