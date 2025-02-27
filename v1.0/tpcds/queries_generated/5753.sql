
WITH sales_summary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        w.w_warehouse_id
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
promotion_info AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name
),
final_report AS (
    SELECT 
        ss.w_warehouse_id,
        ss.total_sales,
        ss.total_orders,
        ss.unique_customers,
        ss.avg_net_profit,
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        pi.p_promo_name,
        pi.total_discount
    FROM 
        sales_summary ss
    LEFT JOIN 
        customer_info ci ON ci.c_customer_id IN (SELECT DISTINCT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim))
    LEFT JOIN 
        promotion_info pi ON pi.total_discount > 0
    ORDER BY 
        ss.total_sales DESC
)
SELECT * 
FROM final_report
LIMIT 100;
