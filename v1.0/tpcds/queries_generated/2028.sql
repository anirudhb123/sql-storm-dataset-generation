
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_category,
        COUNT(DISTINCT ws.web_site_sk) AS total_websites
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        COUNT(*) AS sales_count
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, i.i_brand, i.i_category
),
date_info AS (
    SELECT 
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM 
        date_dim d 
    WHERE 
        d.d_year >= 2022
)
SELECT 
    di.d_year,
    di.d_month_seq,
    ci.c_gender,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers,
    SUM(ss.total_quantity) AS total_units_sold,
    SUM(ss.total_sales) AS total_revenue,
    SUM(ss.avg_profit) AS total_avg_profit,
    II.i_brand,
    II.i_category
FROM 
    sales_summary ss
JOIN 
    date_info di ON ss.ws_sold_date_sk = di.d_date_sk
JOIN 
    customer_info ci ON ss.ws_bill_customer_sk = ci.c_customer_sk
JOIN 
    item_info II ON ss.ws_item_sk = II.i_item_sk
GROUP BY 
    di.d_year, di.d_month_seq, ci.c_gender, II.i_brand, II.i_category
UNION ALL
SELECT 
    di.d_year,
    di.d_month_seq,
    ci.c_gender,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers,
    0 AS total_units_sold,
    0 AS total_revenue,
    0 AS total_avg_profit,
    'N/A' AS i_brand,
    'N/A' AS i_category
FROM 
    date_info di 
LEFT JOIN 
    customer_info ci ON di.d_year IS NOT NULL
WHERE 
    ci.total_websites = 0
GROUP BY 
    di.d_year, di.d_month_seq, ci.c_gender
ORDER BY 
    d_year, d_month_seq, c_gender;
