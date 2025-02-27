
WITH RankedSales AS (
    SELECT 
        ws.web_site_id, 
        ws.sold_date_sk,
        ws.order_number,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws_ext_sales_price DESC) AS rank_sales
    FROM web_sales ws
    WHERE ws_ext_sales_price > (SELECT AVG(ws_ext_sales_price) FROM web_sales)
),
DailyReturns AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(*) AS return_count,
        SUM(cr.return_amt) AS total_return_amt
    FROM catalog_returns cr
    WHERE cr.returned_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023
    )
    GROUP BY cr.returning_customer_sk
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(dr.return_count, 0)) AS total_returns,
        SUM(COALESCE(dr.total_return_amt, 0)) AS total_return_amount,
        CASE 
            WHEN SUM(COALESCE(dr.total_return_amt, 0)) > 500 THEN 'High Return'
            WHEN SUM(COALESCE(dr.total_return_amt, 0)) BETWEEN 200 AND 500 THEN 'Moderate Return'
            ELSE 'Low Return'
        END AS return_category
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN DailyReturns dr ON c.c_customer_sk = dr.returning_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
SalesAggregates AS (
    SELECT 
        rs.web_site_id,
        SUM(rs.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT rs.order_number) AS order_count,
        AVG(rs.ws_ext_sales_price) AS average_order_value
    FROM RankedSales rs
    GROUP BY rs.web_site_id
)
SELECT 
    cm.c_customer_id,
    cm.cd_gender,
    cm.cd_marital_status,
    sa.total_sales,
    sa.order_count,
    sa.average_order_value,
    cm.return_category
FROM CustomerMetrics cm
JOIN SalesAggregates sa ON cm.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = cm.c_customer_id)
WHERE cm.total_returns > 0
ORDER BY sa.total_sales DESC, cm.return_category, cm.c_customer_id
LIMIT 100;
