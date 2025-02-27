
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        C.cd_gender,
        C.cd_income_band_sk,
        D.d_month_seq,
        D.d_year
    FROM 
        web_sales ws
    JOIN 
        customer C ON ws.ws_bill_customer_sk = C.c_customer_sk
    JOIN 
        customer_demographics C_DEMO ON C.c_current_cdemo_sk = C_DEMO.cd_demo_sk
    JOIN 
        date_dim D ON ws.ws_sold_date_sk = D.d_date_sk
    WHERE 
        D.d_year = 2023
        AND C_DEMO.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_sold_date_sk, C.cd_gender, C.cd_income_band_sk, D.d_month_seq, D.d_year
),
average_sales AS (
    SELECT 
        cd_gender,
        cd_income_band_sk,
        d_month_seq,
        AVG(total_quantity) AS avg_quantity,
        AVG(total_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws_sold_date_sk) AS days_active
    FROM 
        sales_data
    GROUP BY 
        cd_gender, cd_income_band_sk, d_month_seq
)
SELECT 
    a.cd_gender,
    a.cd_income_band_sk,
    a.d_month_seq,
    a.avg_quantity,
    a.avg_net_profit,
    RANK() OVER (PARTITION BY a.cd_income_band_sk ORDER BY a.avg_net_profit DESC) AS profit_rank,
    RANK() OVER (PARTITION BY a.cd_income_band_sk ORDER BY a.avg_quantity DESC) AS quantity_rank
FROM 
    average_sales a
ORDER BY 
    a.cd_income_band_sk, profit_rank;
