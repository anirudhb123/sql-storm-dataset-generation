
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT 
        item.i_item_id, 
        item.i_item_desc, 
        item.i_current_price, 
        sd.total_sales, 
        sd.total_profit 
    FROM SalesData sd
    JOIN item ON sd.ws_item_sk = item.i_item_sk
    WHERE sd.rn = 1
),
CustomerReturns AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(wr_return_quantity) AS total_returns, 
        SUM(wr_return_amt) AS total_return_amount
    FROM web_returns
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    COALESCE(tr.total_returns, 0) AS total_returns, 
    COALESCE(tr.total_return_amount, 0) AS total_return_amount,
    ts.total_sales, 
    ts.total_profit
FROM customer c
LEFT JOIN CustomerReturns tr ON c.c_customer_sk = tr.ws_bill_customer_sk
JOIN TopSales ts ON ts.item.i_item_id = (
    SELECT i_item_id FROM item
    WHERE i_item_sk = (
        SELECT ws_item_sk 
        FROM web_sales 
        WHERE ws_bill_customer_sk = c.c_customer_sk 
        ORDER BY ws_net_profit DESC 
        LIMIT 1
    )
)
WHERE c.c_birth_year BETWEEN 1980 AND 1990
  AND (c.c_email_address IS NOT NULL AND c.c_email_address <> '')
ORDER BY total_profit DESC;
