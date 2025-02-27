
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        DATE_DIM.d_date AS sale_date,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_year = 2023
    GROUP BY ws.web_site_id, sale_date
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
SalesAndReturns AS (
    SELECT 
        s.web_site_id,
        sd.sale_date,
        sd.total_sales,
        sd.total_orders,
        sd.total_profit,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount
    FROM SalesData sd
    LEFT JOIN web_site s ON sd.web_site_id = s.web_site_id
    LEFT JOIN CustomerReturns cr ON cr.wr_returning_customer_sk = 
        (SELECT c_customer_sk 
         FROM customer 
         WHERE c_customer_id = (SELECT c_customer_id 
                                 FROM web_sales 
                                 WHERE ws_sales_price > 0 LIMIT 1) LIMIT 1)
)
SELECT 
    s.web_site_id,
    s.sale_date,
    s.total_sales,
    s.total_orders,
    s.total_profit,
    s.total_returns,
    s.total_return_amount,
    (s.total_sales - s.total_return_amount) AS net_sales,
    ROW_NUMBER() OVER (PARTITION BY s.web_site_id ORDER BY s.sale_date DESC) AS sales_rank
FROM SalesAndReturns s
WHERE s.total_sales > 10000
ORDER BY s.web_site_id, s.sale_date DESC;
