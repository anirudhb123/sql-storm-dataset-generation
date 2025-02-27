
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
    UNION ALL
    SELECT 
        date_dim.d_date_sk,
        web_sales.ws_item_sk,
        web_sales.ws_quantity + SalesCTE.total_quantity,
        web_sales.ws_net_profit + SalesCTE.total_profit
    FROM 
        web_sales
    JOIN 
        date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    JOIN 
        SalesCTE ON date_dim.d_date_sk = SalesCTE.ws_sold_date_sk + 1
    WHERE 
        date_dim.d_year = 2023
),
CustomerReturns AS (
    SELECT 
        wr.returned_date_sk,
        wr_refunded_customer_sk,
        SUM(wr_return_quantity) AS total_returned
    FROM 
        web_returns wr
    WHERE 
        wr_return_amt > 0
    GROUP BY 
        wr.returned_date_sk, 
        wr_refunded_customer_sk
),
SalesSummary AS (
    SELECT
        c.c_customer_id,
        COALESCE(SUM(SalesCTE.total_quantity), 0) AS total_sales_quantity,
        COALESCE(SUM(SalesCTE.total_profit), 0) AS total_sales_profit,
        COALESCE(CR.total_returned, 0) AS total_returns
    FROM 
        customer c
    LEFT JOIN 
        SalesCTE ON c.c_customer_sk = ws_bill_customer_sk
    LEFT JOIN 
        CustomerReturns CR ON c.c_customer_sk = CR.w_refunded_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    cs.c_customer_id,
    cs.total_sales_quantity,
    cs.total_sales_profit,
    CASE 
        WHEN cs.total_returns = 0 THEN 'No Returns'
        ELSE 'Returns Present'
    END AS return_status
FROM 
    SalesSummary cs
WHERE 
    cs.total_sales_profit > 1000.00
ORDER BY 
    cs.total_sales_profit DESC
LIMIT 10;
