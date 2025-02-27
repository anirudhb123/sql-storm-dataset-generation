
WITH sales_summary AS (
    SELECT 
        ws_web_site_sk, 
        SUM(ws_net_profit) AS total_net_profit, 
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 10000 AND 20000 
    GROUP BY 
        ws_web_site_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
combined_summary AS (
    SELECT 
        cs.c_customer_sk, 
        cs.cd_gender, 
        cs.cd_marital_status, 
        cs.cd_education_status, 
        ss.total_net_profit, 
        ss.total_orders
    FROM 
        customer_summary cs
    JOIN 
        sales_summary ss ON cs.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_web_site_sk = ss.ws_web_site_sk LIMIT 1)
)
SELECT 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status, 
    COUNT(DISTINCT cs.c_customer_sk) AS customer_count, 
    SUM(cs.total_net_profit) AS total_net_profit,
    AVG(cs.total_orders) AS avg_orders_per_customer
FROM 
    combined_summary cs
JOIN 
    customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY 
    total_net_profit DESC, customer_count DESC;
