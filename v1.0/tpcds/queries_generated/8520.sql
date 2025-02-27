
WITH customer_data AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status, 
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating, 
        cd.cd_dep_count, 
        cd.cd_dep_employed_count, 
        cd.cd_dep_college_count,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        sum(ws.ws_quantity) AS total_quantity,
        sum(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
promotions_data AS (
    SELECT 
        p.p_promo_name, 
        p.p_item_sk, 
        count(p.p_promo_sk) AS promo_count
    FROM promotion p
    GROUP BY p.p_promo_name, p.p_item_sk
),
summary AS (
    SELECT 
        c.c_customer_id,
        sd.total_quantity,
        sd.total_net_profit,
        pd.promo_count
    FROM customer_data c
    JOIN sales_data sd ON c.c_customer_id = sd.ws_bill_customer_sk 
    LEFT JOIN promotions_data pd ON sd.ws_item_sk = pd.p_item_sk
)
SELECT 
    ca.ca_city AS city,
    ca.ca_state AS state,
    COUNT(DISTINCT s.c_customer_id) AS customer_count,
    SUM(s.total_net_profit) AS total_profit,
    AVG(s.total_quantity) AS average_quantity,
    AVG(s.promo_count) AS average_promotions
FROM summary s
JOIN customer_address ca ON s.c_customer_id = ca.ca_address_id
GROUP BY ca.ca_city, ca.ca_state
ORDER BY total_profit DESC, customer_count DESC
LIMIT 10;
