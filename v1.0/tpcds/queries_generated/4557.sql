
WITH ranked_sales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_profit DESC) AS rnk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_month_seq = 3)
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
promotions AS (
    SELECT 
        p.p_promo_id,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_start_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        p.p_promo_id
)

SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(SUM(s.ws_quantity), 0) AS total_quantity,
    COALESCE(SUM(s.ws_net_profit), 0) AS total_net_profit,
    (SELECT COUNT(*) FROM ranked_sales rs WHERE rs.ws_bill_customer_sk = cd.c_customer_sk) AS rank_count,
    r.promo_name,
    p.total_profit
FROM 
    customer_details cd
LEFT JOIN 
    web_sales s ON cd.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN 
    promotions p ON s.ws_promo_sk = p.p_promo_id
LEFT JOIN 
    (SELECT DISTINCT p.promo_id AS promo_name FROM promotion p) r ON r.promo_name IS NOT NULL
WHERE 
    cd.cd_purchase_estimate > 1000
GROUP BY 
    cd.c_first_name, 
    cd.c_last_name, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    r.promo_name,
    p.total_profit
HAVING 
    COALESCE(SUM(s.ws_net_profit), 0) > 500
ORDER BY 
    total_net_profit DESC
LIMIT 10;
