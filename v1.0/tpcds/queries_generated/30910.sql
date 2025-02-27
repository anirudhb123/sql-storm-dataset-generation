
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_date_id, d_date, d_year, d_month_seq, d_week_seq
    FROM date_dim
    WHERE d_date >= '2021-01-01'
    UNION ALL
    SELECT d.d_date_sk, d.d_date_id, d.d_date, d.d_year, d.d_month_seq, d.d_week_seq
    FROM date_dim d
    JOIN DateHierarchy dh ON d.d_date_sk = dh.d_date_sk + 1
),
SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM DateHierarchy)
    GROUP BY ws.web_site_id
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_item_sk
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(SUM(cs.cs_sales_price), SUM(ws.ws_sales_price), SUM(ss.ss_sales_price)) AS total_sales
    FROM item i
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
)
SELECT 
    i.i_item_id,
    COALESCE(ss.total_sales, 0) AS item_sales,
    COALESCE(cr.total_returns, 0) AS item_returns,
    (COALESCE(ss.total_sales, 0) - COALESCE(cr.total_returns, 0)) AS net_sales,
    dh.d_year,
    dh.d_month_seq,
    cs.order_count,
    cs.total_sales AS website_sales
FROM ItemSales i
LEFT JOIN CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
JOIN DateHierarchy dh ON dh.d_date = CURRENT_DATE
LEFT JOIN SalesSummary cs ON 1=1 -- Cartesian joint to get total sales regardless of rank
WHERE (i.i_item_id LIKE 'A%' OR i.i_item_id LIKE 'B%')
  AND dh.d_year BETWEEN 2021 AND 2023
ORDER BY net_sales DESC
FETCH FIRST 100 ROWS ONLY;
