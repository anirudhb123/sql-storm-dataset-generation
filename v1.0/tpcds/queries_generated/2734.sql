
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d WHERE d.d_current_day = 'Y')
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number, ws.ws_sold_date_sk
),
TopProfitableItems AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_profit
    FROM 
        RankedSales r
    WHERE 
        r.rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_value
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(tp.total_quantity), 0) AS quantity_purchased,
    COALESCE(SUM(tp.total_profit), 0) AS total_profit_from_sales,
    COALESCE(cr.total_returns, 0) AS total_returned_items,
    COALESCE(cr.total_return_value, 0) AS total_return_value
FROM 
    customer c
LEFT JOIN 
    TopProfitableItems tp ON c.c_customer_sk = tp.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY 
    total_profit_from_sales DESC, quantity_purchased DESC;
```
