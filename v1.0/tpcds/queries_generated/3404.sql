
WITH SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_moy IN (11, 12)
        )
    GROUP BY 
        ws.web_site_sk
),
TopWebSites AS (
    SELECT 
        web_site_sk,
        total_orders,
        total_profit,
        total_sales
    FROM 
        SalesSummary
    WHERE 
        sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_net_loss) AS total_return_loss
    FROM 
        catalog_returns cr
    WHERE 
        cr_returned_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 
              AND d.d_moy IN (11, 12)
        )
    GROUP BY 
        cr_returning_customer_sk
),
ReturnImpact AS (
    SELECT 
        ws.web_site_sk,
        SUM(COALESCE(cr.total_return_loss, 0)) AS total_return_impact
    FROM 
        TopWebSites tw
    LEFT JOIN 
        CustomerReturns cr ON tw.web_site_sk = cr.cr_returning_customer_sk
    GROUP BY 
        ws.web_site_sk
)
SELECT 
    tw.web_site_sk,
    tw.total_orders,
    tw.total_profit,
    tw.total_sales,
    ri.total_return_impact,
    (tw.total_profit - COALESCE(ri.total_return_impact, 0)) AS net_profit_after_returns,
    CASE 
        WHEN (tw.total_profit - COALESCE(ri.total_return_impact, 0)) < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM 
    TopWebSites tw
LEFT JOIN 
    ReturnImpact ri ON tw.web_site_sk = ri.web_site_sk
ORDER BY 
    net_profit_after_returns DESC;
