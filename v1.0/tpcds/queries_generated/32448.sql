
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                            AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
), CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
), CombinedSales AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        (s.total_sales - COALESCE(r.total_returns, 0) * avg(i.i_current_price)) AS net_sales
    FROM 
        SalesCTE s
    LEFT JOIN 
        CustomerReturns r ON s.ws_item_sk = r.wr_item_sk
    JOIN 
        item i ON s.ws_item_sk = i.i_item_sk
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    sales.total_quantity,
    sales.total_sales,
    sales.total_returns,
    sales.net_sales
FROM 
    CombinedSales sales
JOIN 
    item ON sales.ws_item_sk = item.i_item_sk
WHERE 
    sales.rank <= 10
ORDER BY 
    sales.net_sales DESC
UNION ALL
SELECT 
    'Total' AS i_item_id,
    NULL AS i_item_desc,
    SUM(total_quantity) AS total_quantity,
    SUM(total_sales) AS total_sales,
    SUM(total_returns) AS total_returns,
    SUM(net_sales) AS net_sales
FROM 
    CombinedSales
HAVING 
    SUM(net_sales) > 0;
