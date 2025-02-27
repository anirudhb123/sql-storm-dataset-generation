
WITH sales_summary AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        d.d_year, d.d_month_seq, d.d_quarter_seq
), 
customer_gender_summary AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ss.total_sales) AS total_gender_sales,
        SUM(ss.total_net_profit) AS total_gender_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary ss ON c.c_customer_sk = ss.unique_customers
    GROUP BY 
        cd.cd_gender
), 
store_summary AS (
    SELECT 
        s.s_store_id,
        SUM(ss.total_sales) AS store_sales,
        SUM(ss.total_net_profit) AS store_net_profit
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_id
)
SELECT 
    g.cd_gender,
    g.customer_count,
    g.total_gender_sales,
    g.total_gender_net_profit,
    s.s_store_id,
    s.store_sales,
    s.store_net_profit
FROM 
    customer_gender_summary g
JOIN 
    store_summary s ON g.total_gender_sales = s.store_sales
ORDER BY 
    g.cd_gender, s.store_id;
