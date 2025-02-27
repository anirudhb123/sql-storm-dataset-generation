
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk 
    FROM customer 
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk 
    FROM customer c
    JOIN CustomerHierarchy ch ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue
    FROM web_sales ws
    JOIN web_site w ON w.web_site_sk = ws.ws_web_site_sk
    WHERE w.web_country = 'USA'
    GROUP BY ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned_revenue
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk > 1000
    GROUP BY wr.wr_item_sk
),
TotalSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_revenue,
        COALESCE(rd.total_returned, 0) AS total_returned,
        COALESCE(rd.total_returned_revenue, 0) AS total_returned_revenue,
        sd.total_revenue - COALESCE(rd.total_returned_revenue, 0) AS net_revenue
    FROM SalesData sd
    LEFT OUTER JOIN ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
)
SELECT 
    th.c_first_name,
    th.c_last_name,
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_revenue,
    ts.total_returned,
    ts.total_returned_revenue,
    ts.net_revenue,
    ROW_NUMBER() OVER (PARTITION BY th.c_current_cdemo_sk ORDER BY ts.net_revenue DESC) AS revenue_rank
FROM CustomerHierarchy th
JOIN TotalSales ts ON th.c_current_cdemo_sk = ts.ws_item_sk
WHERE ts.net_revenue > 0
ORDER BY th.c_current_cdemo_sk, revenue_rank
LIMIT 100;
