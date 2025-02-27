
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 0 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_sales_price) AS total_revenue,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
SalesReturns AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_sales,
        sd.total_revenue,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        (sd.total_revenue - COALESCE(rd.total_return_amt, 0)) AS net_revenue
    FROM SalesData sd
    LEFT JOIN ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
),
TopItems AS (
    SELECT 
        sr.ws_item_sk,
        sr.total_sales,
        sr.total_revenue,
        sr.total_returns,
        sr.total_return_amt,
        sr.net_revenue,
        RANK() OVER (ORDER BY sr.net_revenue DESC) AS revenue_rank
    FROM SalesReturns sr
)
SELECT 
    ierr.i_item_id,
    ierr.i_item_desc,
    th.total_sales,
    th.total_revenue,
    th.total_returns,
    th.net_revenue,
    ch.c_first_name,
    ch.c_last_name,
    ch.level
FROM TopItems th
JOIN item ierr ON th.ws_item_sk = ierr.i_item_sk
CROSS JOIN CustomerHierarchy ch
WHERE th.revenue_rank <= 10
AND ch.level = 0
ORDER BY th.net_revenue DESC;
