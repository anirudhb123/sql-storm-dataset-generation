
WITH 
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_income_band_sk
), 
sales_per_item AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        COALESCE(sp.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(sp.total_net_profit, 0) AS total_net_profit
    FROM 
        item i
    LEFT JOIN sales_per_item sp ON i.i_item_sk = sp.ws_item_sk
),
ranked_items AS (
    SELECT 
        ii.i_item_sk,
        ii.i_product_name,
        ii.i_current_price,
        ii.total_quantity_sold,
        ii.total_net_profit,
        RANK() OVER (PARTITION BY ii.total_quantity_sold > 0 ORDER BY ii.total_net_profit DESC) AS rank
    FROM 
        item_info ii
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ri.i_product_name,
    ri.current_price,
    ri.total_quantity_sold,
    ri.total_net_profit,
    ri.rank
FROM 
    customer_info ci
JOIN ranked_items ri ON ci.total_sales > 0
WHERE 
    ci.total_sales > 5
    AND (ci.cd_income_band_sk IN (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound > 50000))
ORDER BY 
    ci.c_last_name, ci.c_first_name, ri.rank;
