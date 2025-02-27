
WITH recursive top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_spent
    FROM customer c
    INNER JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ss.ss_net_paid) > 1000
    ORDER BY total_spent DESC
    LIMIT 10
),
customer_demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM customer_demographics cd
    WHERE cd.cd_purchase_estimate >= 500
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        CASE 
            WHEN ws.ws_net_profit > 0 THEN 'Profitable'
            ELSE 'Not Profitable'
        END AS profit_status
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > 2000000
),
promo_count AS (
    SELECT
        cs.cs_promo_sk,
        COUNT(*) AS promo_usage
    FROM catalog_sales cs
    GROUP BY cs.cs_promo_sk
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(sd.ws_quantity) AS total_sales_quantity,
    SUM(sd.ws_sales_price) AS total_sales_value,
    SUM(sd.ws_net_profit) AS total_net_profit,
    pc.promo_usage
FROM top_customers tc
LEFT JOIN customer cd ON tc.c_customer_sk = cd.c_customer_sk
LEFT JOIN sales_data sd ON tc.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN promo_count pc ON sd.ws_order_number = pc.cs_order_number
WHERE cd.cd_gender IS NOT NULL AND cd.cd_marital_status = 'M'
GROUP BY 
    tc.c_first_name,
    tc.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    pc.promo_usage
ORDER BY total_net_profit DESC
LIMIT 5;
