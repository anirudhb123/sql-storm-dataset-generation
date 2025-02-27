
WITH sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        cd.cd_gender,
        cd.cd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        income_band ib ON cd.cd_purchase_estimate BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
),
aggregated_sales AS (
    SELECT 
        d_year,
        d_month_seq,
        cd_gender,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM 
        sales_data
    GROUP BY 
        d_year, d_month_seq, cd_gender
)
SELECT 
    d_year,
    d_month_seq,
    cd_gender,
    total_quantity,
    total_sales,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM 
    aggregated_sales
WHERE 
    total_sales > 10000
ORDER BY 
    d_year, d_month_seq, sales_rank;
