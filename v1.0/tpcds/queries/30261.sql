
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender IS NULL THEN 'Unknown'
            ELSE cd.cd_gender
        END AS gender,
        COALESCE(hd.hd_buy_potential, 'Undefined') AS buy_potential,
        COUNT(DISTINCT c_preferred_cust_flag) AS pref_cust_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, hd.hd_buy_potential
),
item_details AS (
    SELECT 
        i_item_sk,
        i_product_name,
        AVG(i_current_price) AS avg_price
    FROM 
        item
    GROUP BY 
        i_item_sk, i_product_name
)
SELECT 
    si.ws_item_sk,
    id.i_product_name,
    si.total_quantity,
    si.total_net_profit,
    ci.gender,
    ci.buy_potential,
    id.avg_price,
    (si.total_net_profit / NULLIF(si.total_quantity, 0)) AS avg_net_profit_per_item
FROM 
    sales_summary si
JOIN 
    item_details id ON si.ws_item_sk = id.i_item_sk
JOIN 
    customer_info ci ON ci.c_customer_sk = (SELECT MIN(ws_bill_customer_sk)
                                             FROM web_sales
                                             WHERE ws_item_sk = si.ws_item_sk)
WHERE 
    si.rn = 1 AND 
    (si.total_net_profit > 1000 OR ci.pref_cust_count > 0)
ORDER BY 
    avg_net_profit_per_item DESC
LIMIT 50;
