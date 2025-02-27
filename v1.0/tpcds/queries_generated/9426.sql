
WITH sales_summary AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        c.cd_gender,
        sum(ws.ws_sales_price) AS total_sales,
        count(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_year, d.d_month_seq, d.d_week_seq, c.cd_gender
),
avg_sales AS (
    SELECT
        d_year,
        d_month_seq,
        d_week_seq,
        cd_gender,
        avg(total_sales) AS avg_sales,
        avg(order_count) AS avg_orders
    FROM 
        sales_summary
    GROUP BY 
        d_year, d_month_seq, d_week_seq, cd_gender
),
gender_ranking AS (
    SELECT
        d_year,
        d_month_seq,
        d_week_seq,
        cd_gender,
        RANK() OVER (PARTITION BY d_year, d_month_seq, d_week_seq ORDER BY avg_sales DESC) AS gender_rank
    FROM 
        avg_sales
)
SELECT 
    d_year,
    d_month_seq,
    d_week_seq,
    cd_gender,
    avg_sales,
    avg_orders,
    gender_rank
FROM 
    gender_ranking
WHERE 
    gender_rank = 1
ORDER BY 
    d_year, d_month_seq, d_week_seq;
