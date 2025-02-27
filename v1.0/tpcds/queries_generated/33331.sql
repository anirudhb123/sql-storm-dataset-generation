
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit
    FROM 
        catalog_sales
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
),
customer_returns AS (
    SELECT
        wr_item_sk,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
warehouse_summary AS (
    SELECT 
        inv_date_sk,
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_date_sk, inv_item_sk, inv_warehouse_sk
),
ranked_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        ws.total_inventory,
        RANK() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_profit DESC) AS rank
    FROM 
        sales_data sd
    LEFT JOIN 
        customer_returns cr ON cr.wr_item_sk = sd.ws_item_sk
    LEFT JOIN 
        warehouse_summary ws ON ws.inv_item_sk = sd.ws_item_sk 
)
SELECT 
    rs.ws_item_sk,
    rs.total_quantity,
    rs.total_profit,
    rs.total_returns,
    rs.total_return_amount,
    rs.total_inventory
FROM 
    ranked_sales rs
WHERE 
    rs.rank <= 10
ORDER BY 
    rs.total_profit DESC;
