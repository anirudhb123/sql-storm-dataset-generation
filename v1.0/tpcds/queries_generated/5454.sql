
WITH sales_summary AS (
    SELECT 
        d.d_year,
        c.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_sales,
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
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        d.d_year, c.cd_gender
),
income_summary AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(ws.ws_net_paid) AS avg_transaction_value
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    s.year,
    s.gender,
    s.total_sales,
    s.order_count,
    s.avg_net_profit,
    i.customer_count,
    i.avg_transaction_value
FROM 
    sales_summary s
LEFT JOIN 
    income_summary i ON s.d_year = i.hd_income_band_sk
ORDER BY 
    s.d_year, s.gender;
