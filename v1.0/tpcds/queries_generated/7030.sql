
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        c.c_state,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND d.d_year BETWEEN 2021 AND 2022
    GROUP BY 
        d.d_year, d.d_month_seq, c.c_state
)
SELECT 
    d_year, 
    d_month_seq, 
    c_state, 
    total_sales, 
    order_count, 
    avg_profit,
    RANK() OVER (PARTITION BY c_state ORDER BY total_sales DESC) AS sales_rank
FROM 
    SalesSummary
WHERE 
    total_sales > 100000
ORDER BY 
    d_year, d_month_seq, sales_rank;
