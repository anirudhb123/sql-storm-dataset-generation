
WITH RECURSIVE RevenueCTE AS (
    SELECT 
        w.w_warehouse_id,
        i.i_item_id,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy IN (1, 2, 3)
        ) AND (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy IN (10, 11, 12)
        )
    GROUP BY 
        w.w_warehouse_id, i.i_item_id
    HAVING 
        SUM(ws.ws_net_paid) IS NOT NULL
), RankedRevenue AS (
    SELECT 
        warehouse_id,
        i_item_id,
        total_revenue,
        RANK() OVER (PARTITION BY warehouse_id ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RevenueCTE
)
SELECT 
    cr.returning_customer_sk,
    COUNT(DISTINCT cr_order_number) AS total_returns,
    SUM(cr_return_amount) AS total_returned_amount,
    STRING_AGG(DISTINCT CONCAT(wp_type, ': ', wp_url)) AS return_web_pages
FROM 
    catalog_returns cr
LEFT JOIN 
    web_page wp ON cr.cr_catalog_page_sk = wp.wp_web_page_sk
JOIN 
    RankedRevenue r ON r.i_item_id = cr.cr_item_sk
WHERE 
    r.revenue_rank <= 10 
    AND cr.cr_return_quantity > 0 
    AND cr_refunded_customer_sk IS NOT NULL
GROUP BY 
    cr.returning_customer_sk
ORDER BY 
    total_returns DESC
FETCH FIRST 15 ROWS ONLY;
