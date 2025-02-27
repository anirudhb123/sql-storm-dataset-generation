
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ext_sales_price IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.return_quantity) AS total_returned,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    WHERE 
        wr.returned_date_sk IS NOT NULL
    GROUP BY 
        wr.returning_customer_sk
),
SalesSummary AS (
    SELECT 
        cd.cd_demo_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COALESCE(cr.total_returned, 0) AS total_returns,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(ws.ws_ext_sales_price) AS max_sale
    FROM 
        customer_demographics cd
    LEFT JOIN 
        web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    LEFT JOIN 
        CustomerReturns cr ON cr.returning_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender IN ('F', 'M')
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    ss.cd_demo_sk,
    ss.total_sales,
    ss.total_returns,
    ss.order_count,
    ROUND(ss.total_sales / NULLIF(ss.order_count, 0), 2) AS avg_sales_per_order,
    (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk = ss.cd_demo_sk) AS customer_count
FROM 
    SalesSummary ss
WHERE 
    ss.total_sales > 1000
    AND ss.total_returns < ss.total_sales * 0.1
ORDER BY 
    avg_sales_per_order DESC
FETCH FIRST 10 ROWS ONLY
UNION ALL
SELECT 
    NULL AS cd_demo_sk,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    NULL AS total_returns,
    COUNT(ws.ws_order_number) AS order_count,
    ROUND(SUM(ws.ws_ext_sales_price) / NULLIF(COUNT(ws.ws_order_number), 0), 2) AS avg_sales_per_order
FROM 
    web_sales ws
WHERE 
    ws.ws_ext_sales_price IS NOT NULL
    AND (ws.ws_ship_date_sk IS NULL OR ws.ws_sold_date_sk IS NULL)
    AND ws.ws_ship_mode_sk IN (
        SELECT 
            sm.sm_ship_mode_sk 
        FROM 
            ship_mode sm 
        WHERE 
            sm.sm_type LIKE '%express%'
    )
GROUP BY 
    CASE WHEN (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NULL) > 0 
         THEN 'No Demographics' ELSE 'All Customers' END
HAVING 
    AVG(ws.ws_ext_sales_price) < 500;
