
WITH revenue_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
), 
date_info AS (
    SELECT 
        d_date_sk,
        d_month_seq,
        d_year
    FROM 
        date_dim
    WHERE 
        d_year = 2021
)
SELECT 
    di.d_month_seq,
    di.d_year,
    SUM(rs.total_sales) AS monthly_sales,
    SUM(rs.total_profit) AS monthly_profit,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers,
    AVG(CASE WHEN ci.cd_gender = 'F' THEN 1 ELSE 0 END) * 100 AS female_percentage,
    AVG(CASE WHEN ci.cd_marital_status = 'M' THEN 1 ELSE 0 END) * 100 AS married_percentage,
    AVG(CASE WHEN ci.hd_buy_potential = 'High' THEN 1 ELSE 0 END) * 100 AS high_buy_potential_percentage
FROM 
    revenue_summary rs
JOIN 
    date_info di ON rs.ws_sold_date_sk = di.d_date_sk
JOIN 
    customer_info ci ON ci.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_sold_date_sk = di.d_date_sk)
GROUP BY 
    di.d_month_seq, 
    di.d_year
ORDER BY 
    di.d_year, 
    di.d_month_seq;
