
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sell_date_sk,
        ws_item_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS number_of_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        ws_sell_date_sk, ws_item_sk
), ranked_sales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_sales,
        sd.number_of_sales,
        CASE 
            WHEN sd.rank = 1 THEN 'Top Seller'
            ELSE 'Other'
        END AS sales_category
    FROM 
        sales_data sd
    WHERE 
        sd.rank <= 5
), customer_returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), summary AS (
    SELECT 
        r.ws_item_sk,
        COALESCE(r.total_sales, 0) AS total_sales,
        COALESCE(c.total_returns, 0) AS total_returns,
        (COALESCE(r.total_sales, 0) - COALESCE(c.total_returns, 0)) AS net_sales,
        r.sales_category
    FROM 
        ranked_sales r
    LEFT JOIN 
        customer_returns c ON r.ws_item_sk = c.sr_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_sales,
    s.total_returns,
    s.net_sales,
    i.i_item_desc,
    CASE 
        WHEN s.net_sales > 0 THEN 'Profitable'
        ELSE 'Unprofitable'
    END AS profitability_flag
FROM 
    summary s
JOIN 
    item i ON s.ws_item_sk = i.i_item_sk
WHERE 
    s.net_sales > 0
ORDER BY 
    s.net_sales DESC
LIMIT 10;
