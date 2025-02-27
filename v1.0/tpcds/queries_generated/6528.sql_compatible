
WITH aggregated_sales AS (
    SELECT 
        d.d_year,
        c.c_gender,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, c.c_gender
),
store_sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ss.ss_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year
)
SELECT 
    ag.d_year,
    ag.c_gender,
    ag.total_sales,
    ag.order_count,
    ag.avg_net_profit,
    ss.total_store_sales,
    ss.total_store_orders
FROM 
    aggregated_sales ag
JOIN 
    store_sales_summary ss ON ag.d_year = ss.d_year
ORDER BY 
    ag.d_year, ag.c_gender;
