
WITH item_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023 
    GROUP BY ws.ws_item_sk
), 
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_category,
        i.i_brand
    FROM item i
    JOIN item_sales is ON i.i_item_sk = is.ws_item_sk
), 
sales_summary AS (
    SELECT 
        id.i_item_desc,
        id.i_category,
        id.i_brand,
        is.total_quantity,
        is.total_sales,
        is.total_discount,
        is.total_profit,
        RANK() OVER (PARTITION BY id.i_category ORDER BY is.total_profit DESC) AS rank
    FROM item_sales is
    JOIN item_details id ON is.ws_item_sk = id.i_item_sk
)
SELECT 
    ss.i_item_desc,
    ss.i_category,
    ss.i_brand,
    ss.total_quantity,
    ss.total_sales,
    ss.total_discount,
    ss.total_profit
FROM sales_summary ss
WHERE ss.rank <= 5
ORDER BY ss.i_category, ss.total_profit DESC;
