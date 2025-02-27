
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_id, d.d_year, d.d_month_seq
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
ranked_sales AS (
    SELECT 
        s.c_customer_id,
        s.total_sales,
        s.order_count,
        s.average_profit,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY s.d_year, s.d_month_seq ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        sales_summary s
    JOIN 
        customer_demographics cd ON s.c_customer_id = cd.cd_demo_sk
)
SELECT 
    r.sales_rank,
    r.c_customer_id,
    r.total_sales,
    r.order_count,
    r.average_profit,
    r.cd_gender,
    r.cd_marital_status,
    r.d_year,
    r.d_month_seq
FROM 
    ranked_sales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.d_year, r.d_month_seq, r.sales_rank;
