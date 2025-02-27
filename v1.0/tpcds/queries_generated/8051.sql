
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS ranking
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2459825 AND 2459885 -- Date range for performance testing
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer AS c
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_details AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status
    FROM web_sales AS ws
    JOIN customer_info AS ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT 
    s.ws_order_number,
    ss.total_quantity,
    ss.total_net_profit,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status
FROM sales_details AS s
JOIN ranked_sales AS ss ON s.ws_item_sk = ss.ws_item_sk
JOIN customer_info AS ci ON s.ws_bill_customer_sk = ci.c_customer_sk
WHERE ss.ranking <= 10 -- Top 10 items by net profit
ORDER BY ss.total_net_profit DESC;
