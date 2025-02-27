
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_sk, ws.web_name, ws.ws_sold_date_sk
),
SalesWithPromotions AS (
    SELECT 
        r.web_site_sk,
        r.web_name,
        r.ws_sold_date_sk,
        r.total_sales,
        p.p_promo_name,
        COALESCE(p.p_discount_active, 'N') AS discount_active
    FROM RankedSales r
    LEFT JOIN promotion p ON r.total_sales > p.p_cost
    WHERE r.sales_rank = 1
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        sr_item_sk
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),
FinalResults AS (
    SELECT 
        swp.web_site_sk,
        swp.web_name,
        swp.total_sales,
        swp.p_promo_name,
        swp.discount_active,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        cr.total_returns
    FROM SalesWithPromotions swp
    LEFT JOIN CustomerReturns cr ON swp.ws_sold_date_sk = cr.sr_returned_date_sk
)
SELECT 
    fr.web_site_sk,
    fr.web_name,
    fr.total_sales,
    fr.p_promo_name,
    fr.discount_active,
    fr.total_returned_quantity,
    fr.total_return_amount,
    fr.total_returns,
    CASE 
        WHEN fr.total_return_amount > 0 THEN 'Returns Exist'
        ELSE 'No Returns'
    END AS return_status
FROM FinalResults fr
ORDER BY fr.total_sales DESC, fr.web_name ASC
LIMIT 10;
