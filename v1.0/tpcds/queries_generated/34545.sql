
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    
    UNION ALL 
    
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_net_paid) 
    FROM 
        web_sales AS ws
    JOIN 
        SalesCTE AS s ON ws.ws_item_sk = s.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk > s.ws_sold_date_sk
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk, 
        COUNT(sr_ticket_number) AS total_returns, 
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
),
WebReturns AS (
    SELECT 
        wr_item_sk, 
        COUNT(wr_order_number) AS total_web_returns, 
        SUM(wr_return_amt_inc_tax) AS total_web_return_amt
    FROM 
        web_returns
    WHERE 
        wr_return_quantity > 0
    GROUP BY 
        wr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(SUM(s.total_sales), 0) AS total_web_sales,
    COALESCE(cr.total_returns, 0) AS total_store_returns,
    COALESCE(wr.total_web_returns, 0) AS total_web_returns,
    (COALESCE(SUM(s.total_sales), 0) - 
     COALESCE(cr.total_return_amt, 0) - 
     COALESCE(wr.total_web_return_amt, 0)) AS net_sales
FROM 
    item i
LEFT JOIN 
    SalesCTE s ON i.i_item_sk = s.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
LEFT JOIN 
    WebReturns wr ON i.i_item_sk = wr.wr_item_sk
GROUP BY 
    i.i_item_id
HAVING 
    net_sales > 1000
ORDER BY 
    net_sales DESC;
