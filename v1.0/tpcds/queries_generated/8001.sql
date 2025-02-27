
WITH sales_summary AS (
    SELECT 
        d.d_year,
        c.c_gender,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        d.d_year, c.c_gender
),
demographic_analysis AS (
    SELECT 
        d.d_year,
        CASE 
            WHEN c.cd_marital_status = 'M' THEN 'Married'
            WHEN c.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        SUM(ss.total_quantity) AS total_quantity,
        SUM(ss.total_sales) AS total_sales,
        AVG(ss.avg_net_profit) AS avg_net_profit
    FROM 
        sales_summary ss
    JOIN 
        customer_demographics c ON c.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c.c_gender = c.cd_gender)
    JOIN 
        date_dim d ON ss.d_year = d.d_year
    GROUP BY 
        d.d_year, marital_status
)
SELECT 
    d.d_year,
    da.marital_status,
    da.total_quantity,
    da.total_sales,
    da.avg_net_profit
FROM 
    demographic_analysis da
JOIN 
    date_dim d ON da.d_year = d.d_year
WHERE 
    d.d_year IN (2020, 2021, 2022)
ORDER BY 
    d.d_year, da.marital_status;
