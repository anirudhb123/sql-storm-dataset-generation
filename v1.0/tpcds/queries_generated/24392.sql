
WITH RECURSIVE sales_growth AS (
    SELECT 
        EXTRACT(YEAR FROM d.d_date) AS year, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(CASE WHEN ws.ws_net_profit IS NULL THEN 0 ELSE ws.ws_net_profit END) AS non_null_net_profit,
        ROW_NUMBER() OVER (ORDER BY EXTRACT(YEAR FROM d.d_date)) AS rn
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date BETWEEN '2021-01-01' AND '2023-12-31'
    GROUP BY 
        EXTRACT(YEAR FROM d.d_date)
), customer_data AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IN ('M', 'F') 
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    sg.year,
    sg.total_net_profit,
    COALESCE(SUM(cd.order_count), 0) AS total_orders,
    COALESCE(AVG(cd.avg_net_profit), 0) AS avg_customer_profit,
    COUNT(DISTINCT CASE 
                     WHEN cd.order_count IS NULL THEN NULL 
                     ELSE cd.c_customer_sk 
                   END) AS unique_customers,
    SUM(CASE 
            WHEN cd.cd_marital_status = 'S' THEN 1 
            ELSE 0 
        END) AS single_customers,
    SUM(CASE 
            WHEN cd.cd_gender = 'F' THEN 1 
            ELSE 0 
        END) AS female_customers,
    MAX(sg.non_null_net_profit) FILTER (WHERE sg.non_null_net_profit > 0) AS max_non_null_profit
FROM 
    sales_growth sg
FULL OUTER JOIN 
    customer_data cd ON sg.year = EXTRACT(YEAR FROM cd.avg_net_profit)
GROUP BY 
    sg.year
ORDER BY 
    sg.year DESC
LIMIT 10;
