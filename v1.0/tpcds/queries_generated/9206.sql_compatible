
WITH sales_summary AS (
    SELECT 
        ss.sold_date_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_profit) AS avg_net_profit
    FROM 
        store_sales ss
    JOIN 
        time_dim td ON ss.ss_sold_date_sk = td.d_date_sk
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        td.d_year = 2023 AND 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
    GROUP BY 
        ss.sold_date_sk
),
daily_avg AS (
    SELECT 
        sold_date_sk,
        total_quantity,
        total_sales,
        total_transactions,
        avg_net_profit,
        ROW_NUMBER() OVER (ORDER BY sold_date_sk) AS rk
    FROM 
        sales_summary
)
SELECT 
    d.d_date AS sale_date,
    da.total_quantity,
    da.total_sales,
    da.total_transactions,
    da.avg_net_profit,
    (SELECT AVG(total_sales) FROM daily_avg) AS avg_daily_sales,
    (SELECT SUM(total_sales) FROM daily_avg) AS total_sales_all_time
FROM 
    daily_avg da
JOIN 
    date_dim d ON da.sold_date_sk = d.d_date_sk
WHERE 
    da.rk BETWEEN 1 AND 30
ORDER BY 
    sale_date;
