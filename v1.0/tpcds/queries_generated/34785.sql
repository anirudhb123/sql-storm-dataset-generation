
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    UNION ALL
    SELECT 
        cs.sold_date_sk,
        cs.item_sk,
        cs.order_number,
        cs.quantity,
        cs.sales_price,
        cs.net_profit,
        s.level + 1
    FROM 
        catalog_sales cs 
    JOIN 
        SalesCTE s ON cs.bill_customer_sk = s.ws_bill_customer_sk
    WHERE 
        s.level < 5
), 
ItemStats AS (
    SELECT 
        i_item_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        i_item_sk
),
Returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    i.i_item_sk,
    i.i_product_name,
    COALESCE(is.order_count, 0) AS order_count,
    COALESCE(is.total_profit, 0) AS total_profit,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY COALESCE(is.total_profit, 0) DESC) AS profit_rank
FROM 
    item i
LEFT JOIN 
    ItemStats is ON i.i_item_sk = is.i_item_sk
LEFT JOIN 
    Returns r ON i.i_item_sk = r.sr_item_sk
WHERE 
    i.i_current_price > 50 
    AND (is.order_count IS NULL OR is.order_count > 5)
ORDER BY 
    total_profit DESC, 
    total_returns ASC;
