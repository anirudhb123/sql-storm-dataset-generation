
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COALESCE(ws.ws_ext_discount_amt, 0) AS effective_discount,
        ws.ws_sales_price - COALESCE(ws.ws_ext_discount_amt, 0) AS net_price
    FROM 
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_moy BETWEEN 1 AND 3
        )
), sales_summary AS (
    SELECT 
        rs.ws_item_sk,
        COUNT(rs.ws_order_number) AS total_orders,
        SUM(rs.net_price) AS total_revenue,
        AVG(rs.net_price) AS avg_order_value
    FROM 
        ranked_sales rs
    WHERE 
        rs.price_rank = 1
    GROUP BY 
        rs.ws_item_sk
), returns_summary AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amount) AS total_returned_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_order_number IN (
            SELECT ws.ws_order_number
            FROM web_sales ws
            WHERE ws.ws_sold_date_sk = (
                SELECT MAX(ws2.ws_sold_date_sk)
                FROM web_sales ws2
                WHERE ws2.ws_item_sk = cr.cr_item_sk
            )
        )
    GROUP BY 
        cr.cr_item_sk
), consolidated_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_orders,
        ss.total_revenue,
        ss.avg_order_value,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
        CASE WHEN ss.total_orders = 0 THEN NULL ELSE ss.total_revenue / ss.total_orders END AS revenue_per_order
    FROM 
        sales_summary ss
    LEFT JOIN 
        returns_summary rs ON ss.ws_item_sk = rs.cr_item_sk
)
SELECT 
    cs.ws_item_sk,
    cs.total_orders,
    cs.total_revenue,
    cs.avg_order_value,
    cs.total_returns,
    cs.total_returned_amount,
    cs.revenue_per_order,
    CASE 
        WHEN cs.avg_order_value IS NOT NULL AND cs.avg_order_value > 0 THEN ROUND(cs.total_revenue / cs.total_orders, 2)
        ELSE NULL 
    END AS adjusted_revenue,
    (SELECT COUNT(DISTINCT cr_refunded_customer_sk)
     FROM catalog_returns cr
     WHERE cr.cr_item_sk = cs.ws_item_sk) AS unique_returning_customers
FROM 
    consolidated_sales cs
WHERE 
    cs.total_orders > 0
ORDER BY 
    cs.total_revenue DESC;
