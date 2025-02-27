
WITH sales_summary AS (
    SELECT 
        d.d_year,
        s.s_store_id,
        s.s_store_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, s.s_store_id, s.s_store_name
),
customer_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ss.d_year,
    ss.s_store_id,
    ss.s_store_name,
    ss.total_quantity_sold,
    ss.total_sales,
    ss.avg_net_profit,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_customers,
    cs.total_profit
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.total_sales > 10000
ORDER BY 
    ss.d_year, ss.s_store_id, cs.cd_gender;
