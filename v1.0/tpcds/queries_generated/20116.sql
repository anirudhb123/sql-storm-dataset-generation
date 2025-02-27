
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
        AND ws.ws_net_profit IS NOT NULL
), 
TopSales AS (
    SELECT 
        r.ws_item_sk,
        r.ws_sales_price,
        r.ws_net_profit
    FROM 
        RankedSales r
    WHERE 
        r.price_rank <= 3 AND r.profit_rank <= 5
), 
StoreReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returned,
        AVG(sr.sr_return_amt) AS average_return_amt
    FROM 
        store_returns sr
    WHERE 
        sr.sr_return_quantity > 0
    GROUP BY 
        sr.sr_item_sk
), 
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        ca.ca_city,
        ca.ca_state,
        COALESCE(ir.total_returned, 0) AS total_returns,
        COALESCE(ir.average_return_amt, 0) AS avg_return_amt
    FROM 
        item i
    LEFT JOIN 
        customer_address ca ON i.i_item_sk = ca.ca_address_sk
    LEFT JOIN 
        StoreReturns ir ON i.i_item_sk = ir.sr_item_sk
), 
Summary AS (
    SELECT 
        id.i_item_id,
        id.i_product_name,
        id.ca_city,
        id.ca_state,
        SUM(ts.ws_sales_price) AS sales_total,
        SUM(ts.ws_net_profit) AS total_profit,
        MAX(ts.ws_sales_price) AS max_price,
        MIN(ts.ws_sales_price) AS min_price 
    FROM 
        ItemDetails id
    JOIN 
        TopSales ts ON id.i_item_id = ts.ws_item_sk
    GROUP BY 
        id.i_item_id, id.i_product_name, id.ca_city, id.ca_state
)
SELECT 
    s.*,
    CASE 
        WHEN s.sales_total IS NULL THEN 'No Sales'
        WHEN s.total_profit = 0 THEN 'Break Even'
        WHEN s.total_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status,
    CASE 
        WHEN s.total_returns < 5 THEN 'Low Return'
        WHEN s.total_returns BETWEEN 5 AND 20 THEN 'Moderate Return'
        ELSE 'High Return'
    END AS return_status
FROM 
    Summary s
WHERE 
    s.max_price > 100
ORDER BY 
    s.total_profit DESC,
    NULLIF(s.ca_city, 'Unknown') ASC -- handling potential NULLs in city by treating 'Unknown' as regular
FETCH FIRST 100 ROWS ONLY;
