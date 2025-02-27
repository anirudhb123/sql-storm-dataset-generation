
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > 0
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amount) AS total_returned,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesWithReturns AS (
    SELECT 
        r.rs_item_sk,
        r.ws_order_number,
        COALESCE(c.total_returned, 0) AS total_returned_amount,
        COALESCE(c.return_count, 0) AS return_count,
        r.ws_ext_sales_price - COALESCE(c.total_returned, 0) AS net_sales
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns c ON r.ws_item_sk = c.wr_returning_customer_sk
),
SalesSummary AS (
    SELECT 
        ss.ws_item_sk,
        SUM(ss.net_sales) AS total_net_sales,
        COUNT(DISTINCT ss.ws_order_number) AS total_orders,
        AVG(ss.net_sales) AS avg_net_sales,
        COUNT(CASE WHEN ss.return_count > 0 THEN 1 END) AS orders_with_returns
    FROM 
        SalesWithReturns ss
    GROUP BY 
        ss.ws_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_net_sales,
    s.total_orders,
    s.avg_net_sales,
    CASE 
        WHEN s.orders_with_returns > 0 THEN 'Has Returns' 
        ELSE 'No Returns' 
    END AS return_status,
    COALESCE(d.d_year, 2023) AS sales_year
FROM 
    SalesSummary s
LEFT JOIN 
    date_dim d ON s.total_orders = d.d_dow
WHERE 
    (s.total_net_sales > 1000 AND s.total_orders > 10) 
    OR s.avg_net_sales IS NULL
ORDER BY 
    s.total_net_sales DESC
FETCH FIRST 100 ROWS ONLY;
