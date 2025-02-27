
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        ss.total_orders,
        ss.total_sales,
        ss.avg_net_profit
    FROM 
        customer cs
    JOIN 
        sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ss.rank <= 10
),
demographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        top_customers tc ON cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_id = tc.c_customer_id)
    GROUP BY 
        cd.cd_gender
)
SELECT 
    d.cd_gender,
    d.customer_count,
    d.avg_purchase_estimate,
    COALESCE(tc.total_sales, 0) AS total_sales
FROM 
    demographics d
LEFT JOIN 
    top_customers tc ON d.cd_gender = (SELECT cd_gender FROM customer_demographics WHERE cd_demo_sk = tc.c_current_cdemo_sk)
ORDER BY 
    d.cd_gender;
