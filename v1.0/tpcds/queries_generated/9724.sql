
WITH aggregated_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        h.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
),
sales_analysis AS (
    SELECT 
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        SUM(as.total_quantity) AS total_sold,
        SUM(as.total_revenue) AS total_revenue,
        SUM(as.total_profit) AS total_profit
    FROM 
        aggregated_sales as
    JOIN 
        customer_info ci ON ci.c_customer_sk = as.ws_bill_customer_sk
    JOIN 
        income_band ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ci.cd_gender, ci.cd_marital_status, ci.cd_education_status, 
        ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    cd_gender,
    cd_marital_status,
    cd_education_status,
    income_lower,
    income_upper,
    total_sold,
    total_revenue,
    total_profit,
    (total_revenue / NULLIF(total_sold, 0)) AS avg_revenue_per_sale,
    (total_profit / NULLIF(total_sold, 0)) AS avg_profit_per_sale
FROM 
    sales_analysis
ORDER BY 
    total_revenue DESC
LIMIT 10;
