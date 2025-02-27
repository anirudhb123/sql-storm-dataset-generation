
WITH RankedSales AS (
    SELECT 
        ws.ws_web_page_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_web_page_sk ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
    GROUP BY ws.ws_web_page_sk, ws.ws_item_sk, ws.ws_sales_price
),
CustomerPurchaseStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value,
        MAX(ws.ws_sales_price) AS max_order_value,
        MIN(ws.ws_sales_price) AS min_order_value
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
WebPageStats AS (
    SELECT 
        wp.wp_web_page_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_revenue,
        AVG(ws.ws_net_paid) AS avg_order_value,
        (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_web_page_sk = wp.wp_web_page_sk) AS return_count
    FROM web_page wp
    LEFT JOIN web_sales ws ON wp.wp_web_page_sk = ws.ws_web_page_sk
    GROUP BY wp.wp_web_page_sk
    HAVING COUNT(DISTINCT ws.ws_order_number) > 0
)
SELECT 
    wp.wp_web_page_sk,
    wp.order_count,
    wp.total_revenue,
    wp.avg_order_value,
    COALESCE(CS.total_orders, 0) AS customer_total_orders,
    COALESCE(RS.sales_rank, 0) AS rank_in_sales,
    wp.return_count
FROM WebPageStats wp
LEFT JOIN CustomerPurchaseStats CS ON wp.order_count = CS.total_orders
LEFT JOIN (
    SELECT 
        ws_web_page_sk,
        COUNT(ws_item_sk) AS sales_items
    FROM web_sales
    GROUP BY ws_web_page_sk
    HAVING COUNT(ws_item_sk) > 0
) RS ON wp.wp_web_page_sk = RS.ws_web_page_sk
ORDER BY wp.total_revenue DESC, wp.order_count DESC
LIMIT 10
OPTION (RECOMPILE);
