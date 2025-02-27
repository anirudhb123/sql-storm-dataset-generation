
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
    GROUP BY 
        ws_bill_customer_sk
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        si.total_profit,
        si.order_count
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info si ON ci.c_customer_sk = si.ws_bill_customer_sk
    WHERE 
        ci.rn <= 5
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    COALESCE(hvc.total_profit, 0) AS total_profit,
    COALESCE(hvc.order_count, 0) AS order_count,
    IFNULL(hvc.total_profit / NULLIF(hvc.order_count, 0), 0) AS average_profit_per_order,
    CASE 
        WHEN hvc.total_profit >= 10000 THEN 'Gold'
        WHEN hvc.total_profit >= 5000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier
FROM 
    high_value_customers hvc
FULL OUTER JOIN 
    customer_demographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
WHERE 
    cd.cd_marital_status IS NOT NULL
    AND (
        cd.cd_dependency_count IS NULL OR 
        (cd.cd_dependency_count > 0 AND cd.cd_credit_rating IS NOT NULL)
    )
ORDER BY 
    customer_tier DESC, total_profit DESC;
