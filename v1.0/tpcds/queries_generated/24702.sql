
WITH RankedSales AS (
    SELECT 
        ws_order_number, 
        ws_item_sk, 
        ws_sales_price + COALESCE(ws_ext_ship_cost, 0) AS total_cost,
        DENSE_RANK() OVER (PARTITION BY ws_order_number ORDER BY ws_sales_price DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
),
CustomerAddress AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state, 
        ca_country
    FROM customer_address
    WHERE ca_country = 'USA' 
      AND ca_state IS NOT NULL
),
FilteredReturns AS (
    SELECT 
        sr_order_number,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_order_number
),
FinalSales AS (
    SELECT 
        r.ws_order_number,
        fs.total_cost,
        COALESCE(fr.total_returns, 0) AS total_returns,
        COALESCE(fr.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN fs.total_cost - COALESCE(fr.total_return_amount, 0) < 0 THEN 'Negative Profit'
            ELSE 'Valid Sale' 
        END AS profit_flag
    FROM RankedSales fs
    LEFT JOIN FilteredReturns fr ON fs.ws_order_number = fr.sr_order_number
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(CASE WHEN fs.profit_flag = 'Valid Sale' THEN fs.total_cost END) AS total_valid_sales,
    COUNT(CASE WHEN fs.profit_flag = 'Negative Profit' THEN 1 END) AS negative_profit_count
FROM FinalSales fs
JOIN CustomerAddress ca ON fs.ws_item_sk IN (
    SELECT i_item_sk 
    FROM item 
    WHERE i_current_price > (SELECT AVG(i_current_price) FROM item WHERE i_current_price IS NOT NULL)
)
GROUP BY ca.ca_city, ca.ca_state
HAVING SUM(fs.total_cost) IS NOT NULL
ORDER BY total_valid_sales DESC NULLS LAST;
