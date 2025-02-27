
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        d.d_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2022
    GROUP BY 
        c.c_customer_id, d.d_year
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_sales,
        cs.total_orders,
        cs.total_quantity,
        cs.avg_net_profit,
        cs.d_year
    FROM 
        customer_demographics cd
    JOIN 
        sales_summary cs ON cd.cd_demo_sk = c.c_current_cdemo_sk
),
income_distribution AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(cd.cd_demo_sk) AS demographic_count,
        SUM(cd.total_sales) AS total_sales_by_income_band
    FROM 
        income_band ib
    JOIN 
        customer_demographics cd ON ib.ib_income_band_sk = cd.cd_demo_sk
    GROUP BY 
        ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    id.ib_lower_bound,
    id.ib_upper_bound,
    id.demographic_count,
    id.total_sales_by_income_band,
    CASE 
        WHEN id.demographic_count > 0 THEN (id.total_sales_by_income_band / id.demographic_count) 
        ELSE 0 
    END AS avg_sales_per_demographic
FROM 
    income_distribution id
ORDER BY 
    id.ib_lower_bound;
