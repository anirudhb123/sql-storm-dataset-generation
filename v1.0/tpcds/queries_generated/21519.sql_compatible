
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rnk,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_quantity DESC) AS dense_rnk,
        (SELECT COUNT(*) FROM web_sales ws2 WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk AND ws2.ws_sales_price > ws.ws_sales_price) AS higher_price_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws3.ws_sales_price) FROM web_sales ws3 WHERE ws3.ws_web_site_sk = ws.ws_web_site_sk)
),
AggregatedReturns AS (
    SELECT 
        wr.wr_web_page_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_web_page_sk
),
ReturnMetrics AS (
    SELECT 
        a.web_site_sk,
        a.ws_order_number,
        COALESCE(b.total_returns, 0) AS total_returns,
        COALESCE(b.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN b.total_returns > 0 THEN 1 
            ELSE 0 
        END AS has_returns
    FROM 
        RankedSales a
    LEFT JOIN 
        AggregatedReturns b ON a.ws_order_number = b.wr_web_page_sk
)
SELECT 
    r.web_site_sk,
    SUM(r.ws_sales_price) AS total_sales,
    COUNT(DISTINCT r.ws_order_number) AS order_count,
    MAX(r.total_returns) AS max_returns,
    AVG(r.total_return_amt) AS avg_return_amt,
    SUM(CASE WHEN r.has_returns = 1 THEN 1 ELSE 0 END) AS orders_with_returns
FROM 
    ReturnMetrics r
GROUP BY 
    r.web_site_sk
HAVING 
    SUM(r.ws_sales_price) > 1000
ORDER BY 
    total_sales DESC
LIMIT 10;
