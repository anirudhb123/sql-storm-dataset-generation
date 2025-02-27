
WITH sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_current_price > 0
),
returned_sales AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
store_sales_summary AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM 
        store_sales ss
    WHERE 
        ss.ss_item_sk IS NOT NULL
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(sd.total_net_profit, 0) AS total_net_profit,
    COALESCE(rs.total_returned, 0) AS total_returned,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    sd.price_rank,
    sd.profit_rank
FROM 
    item i
LEFT JOIN 
    store_sales_summary sd ON i.i_item_sk = sd.ss_item_sk
LEFT JOIN 
    returned_sales rs ON i.i_item_sk = rs.wr_item_sk
WHERE 
    i.i_brand_id IN (SELECT DISTINCT ib_income_band_sk FROM household_demographics WHERE hd_buy_potential = 'High')
ORDER BY 
    total_net_profit DESC,
    total_quantity_sold DESC;
