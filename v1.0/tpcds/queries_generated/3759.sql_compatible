
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk 
                                FROM date_dim 
                                WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_net_loss) AS total_loss
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
ItemStats AS (
    SELECT 
        i.i_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_price,
        COALESCE(cr.total_returned, 0) AS total_returned,
        COALESCE(cr.total_loss, 0) AS total_loss
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        CustomerReturns cr ON i.i_item_sk = cr.cr_item_sk
    GROUP BY 
        i.i_item_sk
),
FinalReport AS (
    SELECT 
        is.i_item_sk,
        is.order_count,
        is.avg_price,
        is.total_returned,
        is.total_loss,
        COALESCE(r.r_reason_desc, 'No Reason') AS reason
    FROM 
        ItemStats is
    LEFT JOIN 
        reason r ON is.total_loss > 0 AND r.r_reason_sk = (SELECT MAX(r_reason_sk) FROM reason)
)
SELECT 
    fr.i_item_sk,
    fr.order_count,
    fr.avg_price,
    fr.total_returned,
    fr.total_loss,
    CASE 
        WHEN fr.total_loss > 0 THEN 'High Loss'
        ELSE 'Low Loss'
    END AS loss_category,
    STRING_AGG(fr.reason, ', ') AS reasons
FROM 
    FinalReport fr
GROUP BY 
    fr.i_item_sk, fr.order_count, fr.avg_price, fr.total_returned, fr.total_loss
HAVING 
    fr.total_returned > 10 OR fr.total_loss > 100
ORDER BY 
    fr.total_loss DESC;
