
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_credit_rating
    FROM 
        customer_info ci
    WHERE 
        ci.cd_purchase_estimate > (
            SELECT 
                AVG(cd_purchase_estimate) 
            FROM 
                customer_demographics
        )
),
store_sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(ss_ticket_number) AS total_sales_count
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
ship_mode_summary AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
),
final_report AS (
    SELECT 
        hb.c_customer_id,
        hb.cd_gender,
        ss.total_net_profit,
        ss.total_sales_count,
        sms.order_count
    FROM 
        high_value_customers hb
    LEFT JOIN 
        store_sales_summary ss ON hb.c_customer_sk = ss.ss_store_sk
    LEFT JOIN 
        ship_mode_summary sms ON ss.total_sales_count > 0
    ORDER BY 
        total_net_profit DESC NULLS LAST
)
SELECT 
    fr.c_customer_id,
    fr.cd_gender,
    COALESCE(fr.total_net_profit, 0) AS total_net_profit,
    COALESCE(fr.total_sales_count, 0) AS total_sales_count,
    (SELECT COUNT(*) FROM final_report) AS total_high_value_customers,
    CASE 
        WHEN fr.total_net_profit IS NULL THEN 'Inactive'
        ELSE 'Active'
    END AS customer_status
FROM 
    final_report fr
WHERE 
    fr.cd_gender = 'F'
ORDER BY 
    fr.total_net_profit DESC;
