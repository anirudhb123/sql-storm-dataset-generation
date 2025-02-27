
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
address_info AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        COALESCE(ca_zip, 'UNKNOWN') AS ca_zip_code,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_state) AS city_row
    FROM 
        customer_address
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(ws_total) AS total_web_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        address_info ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        (SELECT 
            ws_bill_customer_sk, SUM(ws_sales_price) AS ws_total
         FROM 
            web_sales 
         GROUP BY 
            ws_bill_customer_sk) web_totals ON c.c_customer_sk = web_totals.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
daily_sales AS (
    SELECT 
        d.d_date,
        SUM(ws_ext_sales_price) AS daily_sales,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    dda.d_date,
    dda.daily_sales,
    c_analysis.ca_city,
    c_analysis.ca_state,
    SUM(ss.total_sold) AS cumulative_sales,
    SUM(CASE 
            WHEN c_analysis.cd_gender = 'M' THEN ss.total_profit
            ELSE 0 
        END) AS male_profit,
    MAX(CASE 
            WHEN city_row = 1 THEN 'Top City'
            ELSE 'Other Cities'
        END) AS city_rank,
    CASE 
        WHEN dda.daily_sales IS NULL THEN 'No Sales'
        WHEN dda.daily_sales < 1000 THEN 'Low Sales'
        WHEN dda.daily_sales >= 1000 AND dda.daily_sales < 5000 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    daily_sales dda
LEFT JOIN 
    customer_analysis c_analysis ON c_analysis.total_web_sales > 0
LEFT JOIN 
    sales_summary ss ON dda.d_date = (SELECT d.d_date FROM date_dim d WHERE d.d_date_sk = ss.ws_sold_date_sk)
GROUP BY 
    dda.d_date, c_analysis.ca_city, c_analysis.ca_state
HAVING 
    COUNT(DISTINCT c_analysis.c_customer_sk) > 5
ORDER BY 
    dda.d_date DESC
LIMIT 100;
