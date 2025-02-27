
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk, ws_order_number
), 
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        h.hd_income_band_sk,
        h.hd_buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
),
high_value_customers AS (
    SELECT 
        ci.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer_info ci
    JOIN 
        web_sales ws ON ci.c_customer_id = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                             AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ci.c_customer_id, ci.c_first_name, ci.c_last_name
    HAVING 
        SUM(ws.ws_net_profit) > 1000
)

SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    hs.total_sales,
    COALESCE(hv.total_profit, 0) AS total_profit
FROM 
    customer_info ci
LEFT JOIN 
    ranked_sales hs ON ci.c_customer_id = hs.ws_order_number
LEFT JOIN 
    high_value_customers hv ON ci.c_customer_id = hv.c_customer_id
WHERE 
    ci.cd_credit_rating IS NOT NULL
  AND 
    hs.rank = 1
ORDER BY 
    total_profit DESC,
    ci.c_last_name ASC;
