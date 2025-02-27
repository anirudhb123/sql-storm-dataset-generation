
WITH RECURSIVE SalesWithReturns AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        (ws_quantity * ws_sales_price) AS total_sales,
        0 AS total_returns
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)

    UNION ALL

    SELECT 
        s.cs_order_number AS ws_order_number,
        s.cs_item_sk AS ws_item_sk,
        s.cs_quantity * -1 AS ws_quantity, 
        s.cs_sales_price * -1 AS ws_sales_price,
        (s.cs_quantity * -1 * s.cs_sales_price) AS total_sales,
        (s.cs_quantity * -1) AS total_returns
    FROM 
        catalog_sales s
    JOIN SalesWithReturns sr ON sr.ws_order_number = s.cs_order_number AND sr.ws_item_sk = s.cs_item_sk
    WHERE 
        sr.ws_order_number IS NOT NULL
)

SELECT 
    w.ws_order_number,
    w.ws_item_sk,
    SUM(w.ws_quantity) AS total_quantity_sold,
    SUM(w.total_sales) AS total_sales_revenue,
    COALESCE(SUM(r.total_returns), 0) AS total_returns,
    (SUM(w.total_sales) + COALESCE(SUM(r.total_returns), 0)) AS net_sales,
    COUNT(DISTINCT w.ws_order_number) AS distinct_orders
FROM 
    SalesWithReturns w
LEFT JOIN 
    (SELECT 
         wr_order_number,
         wr_item_sk,
         SUM(wr_return_quantity) AS total_returns
     FROM 
         web_returns
     GROUP BY 
         wr_order_number, 
         wr_item_sk) r ON w.ws_order_number = r.wr_order_number AND w.ws_item_sk = r.wr_item_sk
GROUP BY 
    w.ws_order_number,
    w.ws_item_sk
ORDER BY 
    net_sales DESC
FETCH FIRST 10 ROWS ONLY;
