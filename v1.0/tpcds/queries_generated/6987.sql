
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020 AND d.d_year <= 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, d.d_year, d.d_month_seq
), ranked_customers AS (
    SELECT 
        customer_id,
        first_name,
        last_name,
        gender,
        marital_status,
        year,
        month_seq,
        total_net_profit,
        total_orders,
        DENSE_RANK() OVER (PARTITION BY year, month_seq ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        customer_data
)
SELECT 
    customer_id,
    first_name,
    last_name,
    gender,
    marital_status,
    year,
    month_seq,
    total_net_profit,
    total_orders,
    profit_rank
FROM 
    ranked_customers
WHERE 
    profit_rank <= 10
ORDER BY 
    year, month_seq, profit_rank;
