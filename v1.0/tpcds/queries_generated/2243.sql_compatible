
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE i.i_current_price > 0 
      AND s.s_state = 'CA'
    GROUP BY ws.web_site_sk, ws.web_name
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returns,
        SUM(cr.return_amt) AS total_return_amount
    FROM web_returns cr
    GROUP BY cr.returning_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate BETWEEN 1000 AND 2000
),
SalesComparison AS (
    SELECT 
        r.web_site_sk,
        r.total_sales,
        c.total_returns,
        COALESCE(c.total_returns, 0) AS effective_returns
    FROM RankedSales r
    LEFT JOIN CustomerReturns c ON r.web_site_sk = c.returning_customer_sk
    WHERE r.sales_rank = 1
)
SELECT 
    sc.web_site_sk,
    sc.total_sales,
    sc.effective_returns,
    sc.total_sales - sc.effective_returns AS net_sales,
    CASE 
        WHEN sc.total_sales > 10000 THEN 'High Performer'
        WHEN sc.total_sales > 5000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM SalesComparison sc
LEFT JOIN HighValueCustomers hv ON sc.web_site_sk = hv.c_customer_sk
WHERE hv.c_customer_sk IS NOT NULL
ORDER BY net_sales DESC;
