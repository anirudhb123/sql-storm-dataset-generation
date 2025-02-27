
WITH CustomerReturns AS (
    SELECT 
        COALESCE(sr.return_quantity, 0) AS return_quantity,
        COALESCE(sr.return_amt, 0) AS return_amount,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        EXTRACT(YEAR FROM d.d_date) AS return_year
    FROM 
        store_returns sr
    FULL OUTER JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE 
        (sr.sr_return_quantity IS NOT NULL OR sr.sr_return_amt IS NOT NULL)
        AND (c.c_current_cdemo_sk IS NOT NULL OR cd.cd_gender IS NOT NULL)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, return_year
), 
PromotionalReturns AS (
    SELECT 
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit,
        SUM(COALESCE(cr.cr_return_quantity, 0)) AS catalog_return_quantity,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS catalog_return_amount,
        c.c_customer_sk
    FROM 
        catalog_returns cr
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws ON cr.cr_item_sk = ws.ws_item_sk AND cr.cr_order_number = ws.ws_order_number
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_returns,
    r.return_quantity,
    r.return_amount,
    COALESCE(p.total_profit, 0) AS total_profit,
    p.catalog_return_quantity,
    CASE 
        WHEN r.total_returns > 0 AND p.catalog_return_quantity IS NULL THEN 'High Return, No Catalog Returns'
        WHEN p.catalog_return_quantity > 0 AND r.total_returns IS NULL THEN 'Catalog Returns, No Store Returns'
        ELSE 'Mixed Returns'
    END AS return_category
FROM 
    CustomerReturns r
LEFT JOIN 
    PromotionalReturns p ON r.c_customer_sk = p.c_customer_sk
WHERE 
    r.return_year = (SELECT MAX(return_year) FROM CustomerReturns)
ORDER BY 
    r.total_returns DESC, r.return_amount DESC
LIMIT 100;
