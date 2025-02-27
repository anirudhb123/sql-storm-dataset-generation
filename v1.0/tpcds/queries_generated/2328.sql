
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
), CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    JOIN 
        web_sales ws ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    GROUP BY 
        wr.returning_customer_sk
), Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        SUM(CASE WHEN ws.ws_net_paid > 0 THEN 1 ELSE 0 END) AS promo_sales_count,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk, p.p_promo_name
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    coalesce(rs.total_sales, 0) AS total_sales,
    coalesce(cr.total_return_amount, 0) AS total_return_amount,
    p.promo_sales_count,
    p.order_count
FROM 
    customer cs
LEFT JOIN 
    RankedSales rs ON cs.c_customer_sk = rs.web_site_sk
LEFT JOIN 
    CustomerReturns cr ON cs.c_customer_sk = cr.returning_customer_sk
LEFT JOIN 
    Promotions p ON rs.web_site_sk = p.p_promo_sk
WHERE 
    (coalesce(rs.total_sales, 0) > 1000 OR coalesce(cr.total_return_amount, 0) > 500) 
    AND (p.promo_sales_count IS NOT NULL OR p.order_count IS NOT NULL)
ORDER BY 
    total_sales DESC, total_return_amount DESC;
