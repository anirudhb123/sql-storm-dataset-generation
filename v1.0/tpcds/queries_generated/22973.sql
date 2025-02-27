
WITH SalesData AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rn,
        COUNT(*) OVER (PARTITION BY ws.web_site_sk) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND
        dd.d_moy BETWEEN 1 AND 6
),
TopSales AS (
    SELECT 
        web_site_sk,
        ws_order_number,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_profit
    FROM 
        SalesData
    WHERE 
        rn <= 10
),
ProfitAnalysis AS (
    SELECT 
        ws.web_site_sk, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_net_profit) AS highest_profit,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
    GROUP BY 
        ws.web_site_sk
),
CombinedData AS (
    SELECT 
        ta.web_site_sk,
        ta.ws_order_number,
        ta.ws_sales_price,
        ta.ws_ext_sales_price,
        pa.total_profit,
        pa.order_count,
        pa.highest_profit,
        pa.avg_profit
    FROM 
        TopSales ta
    LEFT JOIN 
        ProfitAnalysis pa ON ta.web_site_sk = pa.web_site_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cd.cd_gender, 'N/A') AS gender,
    COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
    ROUND(SUM(cd.cd_purchase_estimate)/NULLIF(COUNT(cd_demo_sk), 0), 2) AS avg_purchase_estimate,
    COUNT(DISTINCT cd.cd_demo_sk) AS demographics_count,
    MAX(CASE WHEN cd.cd_credit_rating = 'High' THEN 1 ELSE 0 END) OVER () AS has_high_credit_rating,
    STRING_AGG(DISTINCT CONCAT('Order:', ta.ws_order_number, ' | Price:', ta.ws_sales_price), '; ') AS order_summary
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    CombinedData ta ON c.c_customer_sk = ta.web_site_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
HAVING 
    COUNT(DISTINCT ta.ws_order_number) > 5 OR 
    MAX(ta.ws_sales_price) > 100
ORDER BY 
    avg_purchase_estimate DESC, 
    c.c_last_name;
