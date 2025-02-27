
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv ON ws.ws_item_sk = inv.inv_item_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
        AND cd.cd_gender = 'M'
        AND inv.inv_quantity_on_hand > 0
    GROUP BY ws.web_site_sk
),
TopSales AS (
    SELECT web_site_sk, total_sales
    FROM RankedSales
    WHERE sales_rank <= 10
),
RecentReturns AS (
    SELECT
        wr.wr_web_page_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_returned
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    WHERE wr.wr_returned_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY wr.wr_web_page_sk
)
SELECT
    w.web_site_name,
    ts.total_sales,
    COALESCE(rr.total_returned, 0) AS total_returned,
    (ts.total_sales - COALESCE(rr.total_returned, 0)) AS net_sales,
    (COALESCE(rr.total_returned, 0) / NULLIF(ts.total_sales, 0)) * 100 AS return_percentage
FROM TopSales ts
JOIN web_site w ON ts.web_site_sk = w.web_site_sk
LEFT JOIN RecentReturns rr ON w.web_site_sk = rr.wr_web_page_sk
ORDER BY net_sales DESC;
