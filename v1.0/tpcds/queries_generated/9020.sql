
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        w.w_warehouse_name,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        cd.gender,
        cd.education_status,
        cd.credit_rating
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        d.d_year = 2023 
        AND d.d_month_seq IN (1, 2, 3)
),
ProfitSummary AS (
    SELECT 
        w_warehouse_name,
        d_year,
        d_month_seq,
        d_week_seq,
        gender,
        education_status,
        credit_rating,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_quantity) AS total_quantity
    FROM 
        SalesData
    GROUP BY 
        w_warehouse_name, d_year, d_month_seq, d_week_seq, gender, education_status, credit_rating
)
SELECT 
    w_warehouse_name,
    d_year,
    d_month_seq,
    d_week_seq,
    gender,
    education_status,
    credit_rating,
    total_net_profit,
    total_quantity,
    (total_net_profit / NULLIF(total_quantity, 0)) AS avg_profit_per_unit
FROM 
    ProfitSummary
WHERE 
    total_net_profit > 10000
ORDER BY 
    total_net_profit DESC;
