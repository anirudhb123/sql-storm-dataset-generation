
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        MAX(ws.ws_sold_date_sk) AS last_sale_date,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL
    GROUP BY ws.web_site_sk
),
CustomerReturns AS (
    SELECT 
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        COUNT(DISTINCT wr.wr_returning_customer_sk) AS unique_customers
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    WHERE wr.wr_return_quantity > 0
    GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        rs.web_site_sk,
        rs.total_sales,
        rs.last_sale_date,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.unique_customers, 0) AS unique_customers
    FROM RankedSales rs
    LEFT JOIN CustomerReturns cr ON rs.web_site_sk = cr.wr_item_sk
    WHERE rs.sales_rank <= 5
),
RankedReports AS (
    SELECT 
        *,
        CASE 
            WHEN total_returns > total_sales * 0.1 THEN 'High Return Rate'
            WHEN total_returns = 0 THEN 'No Returns'
            ELSE 'Normal'
        END AS return_status,
        RANK() OVER (ORDER BY total_sales DESC, total_returns ASC) AS report_rank
    FROM SalesWithReturns
)

SELECT 
    r.web_site_sk,
    r.total_sales,
    r.total_returns,
    r.unique_customers,
    r.return_status
FROM RankedReports r
WHERE r.return_status LIKE 'High%' AND r.total_sales IS NOT NULL
ORDER BY r.total_sales DESC NULLS LAST;
