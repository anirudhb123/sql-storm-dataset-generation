
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
item_info AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_desc, 
        i.i_current_price, 
        i.i_brand 
    FROM 
        item i 
    WHERE 
        i.i_current_price IS NOT NULL
),
sales_summary AS (
    SELECT 
        si.ws_item_sk,
        ii.i_item_desc,
        SUM(si.ws_net_paid) AS total_sales,
        COUNT(si.ws_order_number) AS total_orders,
        MAX(si.ws_net_paid_inc_tax) AS max_paid_inc_tax,
        MIN(si.ws_net_paid_inc_ship) AS min_paid_inc_ship
    FROM 
        web_sales si 
    JOIN 
        item_info ii ON si.ws_item_sk = ii.i_item_sk
    GROUP BY 
        si.ws_item_sk, ii.i_item_desc
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ss.i_item_desc,
    ss.total_sales,
    ss.total_orders,
    ss.max_paid_inc_tax,
    ss.min_paid_inc_ship,
    COALESCE((SELECT COUNT(*) FROM store_sales s WHERE s.ss_item_sk = ss.ws_item_sk AND s.ss_sales_price IS NOT NULL), 0) AS store_sales_count,
    (SELECT SUM(sr_return_amt) 
     FROM store_returns sr 
     WHERE sr.sr_item_sk = ss.ws_item_sk) AS total_store_returns
FROM 
    customer_info ci
JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
WHERE 
    ci.cd_income_band_sk IS NOT NULL 
    AND ss.total_sales > 1000
ORDER BY 
    total_sales DESC
FETCH FIRST 100 ROWS ONLY;
