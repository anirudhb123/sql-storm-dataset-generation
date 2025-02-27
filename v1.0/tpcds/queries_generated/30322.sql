
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        COALESCE(SUM(ss.net_profit), 0) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY COALESCE(SUM(ss.net_profit), 0) DESC) AS rank
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s_store_sk, s_store_name, s_number_employees, s_floor_space
), high_performance_stores AS (
    SELECT 
        store_name,
        total_net_profit
    FROM 
        sales_hierarchy
    WHERE 
        rank <= 5
), demographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS customer_count,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
), monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS total_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
), performance_comparison AS (
    SELECT 
        h.store_name,
        h.total_net_profit,
        d.cd_gender,
        d.customer_count,
        d.avg_vehicle_count,
        d.married_count,
        m.total_sales
    FROM 
        high_performance_stores h
    JOIN
        demographics d ON d.customer_count > 100
    JOIN
        monthly_sales m ON m.total_sales > 10000
)
SELECT 
    p.store_name,
    p.total_net_profit,
    p.cd_gender,
    p.customer_count,
    p.avg_vehicle_count,
    p.married_count,
    p.total_sales
FROM 
    performance_comparison p
WHERE 
    (p.cd_gender IS NOT NULL OR p.store_name IS NOT NULL)
ORDER BY 
    p.total_net_profit DESC
LIMIT 10;
