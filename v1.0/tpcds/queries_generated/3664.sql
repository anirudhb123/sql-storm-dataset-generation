
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.web_site_id, ws.ws_sold_date_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns AS wr
    GROUP BY 
        wr.wr_item_sk
),
SalesAndReturns AS (
    SELECT 
        ss.web_site_id,
        ss.ws_sold_date_sk,
        ss.total_quantity,
        ss.total_sales,
        ss.order_count,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM 
        SalesSummary AS ss
    LEFT JOIN 
        CustomerReturns AS cr ON ss.web_site_id = cr.wr_item_sk
)
SELECT 
    sa.web_site_id,
    dd.d_date AS sales_date,
    sa.total_quantity,
    sa.total_sales,
    sa.order_count,
    sa.total_returns,
    sa.total_return_amount,
    (sa.total_sales - sa.total_return_amount) AS net_sales,
    (sa.total_quantity - sa.total_returns) AS net_quantity,
    RANK() OVER (PARTITION BY sa.web_site_id ORDER BY (sa.total_sales - sa.total_return_amount) DESC) AS sales_rank
FROM 
    SalesAndReturns AS sa
JOIN 
    date_dim AS dd ON sa.ws_sold_date_sk = dd.d_date_sk
WHERE 
    dd.d_year = 2023 AND 
    (sa.total_sales > 1000 OR sa.order_count > 10)
ORDER BY 
    sa.web_site_id, net_sales DESC;
