
WITH RECURSIVE customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_gender ORDER BY COALESCE(cd.cd_purchase_estimate, 0) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
), 
store_sales_summary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_store_sk
), 
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name, 
        ci.c_last_name, 
        si.total_net_paid
    FROM 
        customer_info ci
    JOIN 
        store_sales_summary si ON ci.rn <= 10
    WHERE 
        ci.purchase_estimate > (SELECT AVG(purchase_estimate) FROM customer_info)
    ORDER BY 
        si.total_net_paid DESC 
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    sm.sm_type AS shipping_method,
    si.avg_sales_price,
    COALESCE(sub.total_returns, 0) AS total_returns,
    CASE 
        WHEN si.total_net_paid IS NULL THEN 'No sales data'
        WHEN si.total_net_paid > 1000 THEN 'High Value'
        ELSE 'Regular Value'
    END AS customer_category
FROM 
    high_value_customers ci
LEFT JOIN 
    store_sales_summary si ON ci.c_customer_sk = si.ss_store_sk
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (SELECT ws.ws_ship_mode_sk FROM web_sales ws WHERE ci.c_customer_sk = ws.ws_bill_customer_sk LIMIT 1)
LEFT JOIN 
    (SELECT 
         wr_returning_customer_sk,
         COUNT(*) AS total_returns
     FROM 
         web_returns
     GROUP BY 
         wr_returning_customer_sk) sub ON ci.c_customer_sk = sub.wr_returning_customer_sk
WHERE 
    ci.total_net_paid IS NOT NULL
ORDER BY 
    ci.c_last_name, ci.c_first_name;
