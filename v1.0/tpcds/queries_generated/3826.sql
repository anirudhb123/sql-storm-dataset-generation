
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
item_profit AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_net_profit) AS item_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
),
top_items AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        RANK() OVER (ORDER BY item_profit DESC) AS rank
    FROM 
        item_profit i
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    (SELECT ib.ib_lower_bound 
     FROM income_band ib 
     WHERE ib.ib_income_band_sk = ci.income_band) AS lower_income_bound,
    (SELECT ib.ib_upper_bound 
     FROM income_band ib 
     WHERE ib.ib_income_band_sk = ci.income_band) AS upper_income_bound,
    ti.i_product_name,
    ti.rank,
    ci.total_orders,
    ci.total_net_profit
FROM 
    customer_info ci
LEFT JOIN 
    top_items ti ON ci.total_net_profit > (SELECT AVG(total_net_profit) FROM customer_info) AND ti.rank <= 10
WHERE 
    ci.total_orders > 5 
ORDER BY 
    ci.total_net_profit DESC, ci.c_last_name ASC;
