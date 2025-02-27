
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS item_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price
    FROM 
        item i
),
SoldItems AS (
    SELECT 
        s.ws_sold_date_sk,
        d.i_item_sk,
        d.i_item_desc,
        s.total_quantity,
        s.total_sales,
        d.i_current_price,
        (s.total_sales - (s.total_quantity * d.i_current_price)) AS profit_loss
    FROM 
        SalesCTE s
    JOIN 
        ItemDetails d ON s.ws_item_sk = d.i_item_sk
    WHERE 
        s.item_rank <= 5
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IS NOT NULL
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
)
SELECT 
    d.d_date AS SaleDate,
    s.i_item_desc AS ItemDescription,
    s.total_quantity AS SoldQuantity,
    s.total_sales AS TotalSales,
    s.profit_loss AS ProfitLoss,
    COALESCE(r.total_returned_quantity, 0) AS ReturnedQuantity,
    COALESCE(r.total_return_amt, 0) AS TotalReturnedAmt
FROM 
    SoldItems s
LEFT JOIN 
    date_dim d ON s.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    CustomerReturns r ON s.ws_item_sk = r.sr_item_sk AND d.d_date_sk = r.sr_returned_date_sk
WHERE 
    d.d_year = 2023
ORDER BY 
    d.d_date, s.total_sales DESC;
