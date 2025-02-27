
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        sales.total_quantity,
        sales.total_profit,
        ROW_NUMBER() OVER (ORDER BY sales.total_profit DESC) AS sales_rank
    FROM 
        SalesCTE sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.rank = 1
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    ts.i_item_id,
    ts.i_product_name,
    ts.total_quantity,
    ts.total_profit,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN ts.total_profit > 1000 THEN 'High Profit'
        WHEN ts.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    TopSales ts
LEFT JOIN 
    CustomerReturns cr ON ts.ws_item_sk = cr.sr_item_sk
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.total_profit DESC;
