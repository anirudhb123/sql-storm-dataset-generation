
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    
    UNION ALL

    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
), 

SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE w.web_country = 'USA'
    GROUP BY ws.ws_order_number, ws.ws_item_sk
),

ReturnsData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),

RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        (sd.total_sales - COALESCE(rd.total_return_amt, 0)) AS net_sales
    FROM SalesData sd
    LEFT JOIN ReturnsData rd ON sd.ws_item_sk = rd.wr_item_sk
    WHERE sd.sales_rank <= 10
)

SELECT 
    ch.c_first_name,
    ch.c_last_name,
    r.ws_item_sk,
    r.total_quantity,
    r.total_sales,
    r.total_returns,
    r.net_sales,
    CASE
        WHEN r.net_sales > 1000 THEN 'High Value'
        WHEN r.net_sales > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category
FROM CustomerHierarchy ch
JOIN RankedSales r ON ch.c_current_cdemo_sk = ch.c_customer_sk
ORDER BY r.net_sales DESC, ch.level, ch.c_last_name;
