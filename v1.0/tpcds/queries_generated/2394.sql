
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_by_gender AS (
    SELECT 
        ci.cd_gender,
        SUM(ss.total_sales) AS gender_sales,
        SUM(ss.total_quantity) AS gender_quantity
    FROM 
        sales_summary ss
    JOIN 
        customer_info ci ON ss.ws_sold_date_sk IN (
            SELECT 
                ws_sold_date_sk 
            FROM 
                web_sales ws 
            WHERE 
                ws.ws_bill_customer_sk = ci.c_customer_sk
        )
    GROUP BY 
        ci.cd_gender
),
aggregated_sales AS (
    SELECT 
        sm.sm_type,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_type
)
SELECT 
    s.sm_type,
    a.total_net_paid,
    a.avg_net_paid,
    g.gender_sales,
    g.gender_quantity
FROM 
    aggregated_sales a
LEFT JOIN 
    sales_by_gender g ON a.total_net_paid > 50000 -- Complicated predicate for filtering
CROSS JOIN 
    (SELECT DISTINCT cd_gender FROM customer_demographics) AS distinct_genders
ORDER BY 
    a.total_net_paid DESC;
