
WITH RankedSales AS (
  SELECT 
    ws.web_site_sk,
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_ext_sales_price,
    ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
  FROM 
    web_sales ws
  JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE 
    d.d_year = 2022
    AND ws.ws_ext_sales_price IS NOT NULL
),
TopSales AS (
  SELECT 
    r.web_site_sk,
    r.ws_order_number,
    r.ws_ext_sales_price
  FROM 
    RankedSales r
  WHERE 
    r.sales_rank <= 5
),
CustomerReturns AS (
  SELECT 
    wr.returning_customer_sk,
    SUM(wr.return_quantity) AS total_returned,
    COUNT(DISTINCT wr.reason_sk) AS unique_reasons
  FROM 
    web_returns wr
  GROUP BY 
    wr.returning_customer_sk
),
ReturnImpact AS (
  SELECT 
    c.c_customer_sk,
    CASE 
      WHEN cr.total_returned IS NULL THEN 'No Returns'
      WHEN cr.total_returned > 0 THEN 'Returned Goods'
      ELSE 'Error'
    END AS return_status,
    COALESCE(cr.unique_reasons, 0) AS unique_return_count
  FROM 
    customer c
  LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
),
WebSalesSummary AS (
  SELECT 
    w.web_site_id,
    COUNT(ts.ws_order_number) AS total_orders,
    SUM(ts.ws_ext_sales_price) AS total_sales,
    AVG(ts.ws_ext_sales_price) AS avg_order_value
  FROM 
    TopSales ts
  JOIN 
    web_site w ON ts.web_site_sk = w.web_site_sk
  GROUP BY 
    w.web_site_id
)

SELECT 
  w.ws_id AS WebSite,
  COALESCE(s.total_orders, 0) AS TotalOrders,
  COALESCE(s.total_sales, 0) AS TotalSales,
  COALESCE(s.avg_order_value, 0) AS AverageOrderValue,
  ci.return_status AS ReturnStatus,
  ci.unique_return_count AS UniqueReturnCount
FROM 
  WebSalesSummary s
FULL OUTER JOIN 
  ReturnImpact ci ON ci.c_customer_sk = (SELECT MIN(c.c_customer_sk) FROM customer c)
JOIN 
  warehouse w ON s.web_site_id = w.w_warehouse_id
WHERE 
  (ci.return_status IS NOT NULL OR s.total_orders IS NOT NULL)
ORDER BY 
  w.ws_id, 
  TotalSales DESC NULLS LAST;
