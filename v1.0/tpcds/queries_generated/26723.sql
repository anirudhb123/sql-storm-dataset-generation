
WITH customer_info AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
date_analysis AS (
    SELECT 
        d.d_year, 
        d.d_month_seq, 
        COUNT(ws.ws_order_number) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
sales_analysis AS (
    SELECT 
        ci.c_customer_sk, 
        ci.full_name, 
        ci.ca_city,
        ci.ca_state,
        da.d_year,
        da.d_month_seq,
        da.total_sales,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
    FROM 
        customer_info ci
    LEFT JOIN 
        date_analysis da ON 1 = 1
    LEFT JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk 
        AND da.d_year = YEAR(ws.ws_sold_date_sk) 
        AND da.d_month_seq = MONTH(ws.ws_sold_date_sk)
    GROUP BY 
        ci.c_customer_sk, ci.full_name, ci.ca_city, ci.ca_state, da.d_year, da.d_month_seq
)
SELECT 
    CONCAT(full_name, ' from ', ca_city, ', ', ca_state) AS customer_location,
    d_year, 
    d_month_seq, 
    total_sales,
    total_net_profit
FROM 
    sales_analysis
ORDER BY 
    d_year DESC, d_month_seq DESC, total_net_profit DESC
LIMIT 100;
