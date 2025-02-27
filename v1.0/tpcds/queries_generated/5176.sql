
WITH monthly_sales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
), 
store_sales_summary AS (
    SELECT 
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_profit) AS store_total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_total_orders
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_sold_date_sk
),
customer_info AS (
    SELECT 
        cd.cd_marital_status,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(c.c_birth_month) AS total_birth_month
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_marital_status, cd.cd_gender
),
promotional_efforts AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS promo_profit,
        COUNT(DISTINCT ws.ws_order_number) AS promo_orders
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
)
SELECT 
    ms.d_year,
    ms.d_month_seq,
    ms.total_profit,
    ms.total_orders,
    ms.total_quantity,
    ss.store_total_profit,
    ss.store_total_orders,
    ci.customer_count,
    ci.total_birth_month,
    pe.promo_name,
    pe.promo_profit,
    pe.promo_orders
FROM 
    monthly_sales ms
LEFT JOIN 
    store_sales_summary ss ON ms.d_month_seq = ss.ss_sold_date_sk
LEFT JOIN 
    customer_info ci ON ci.cd_marital_status = 'M' AND ci.cd_gender = 'F'
LEFT JOIN 
    promotional_efforts pe ON pe.promo_profit > 10000
ORDER BY 
    ms.d_year, ms.d_month_seq;
