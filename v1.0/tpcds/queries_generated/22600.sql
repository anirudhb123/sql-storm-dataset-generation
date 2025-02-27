
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rnk
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL AND ws.ws_ship_date_sk IS NOT NULL
),
CustomerSpending AS (
    SELECT 
        c.c_customer_sk,
        SUM(CASE WHEN ws.ws_net_paid IS NOT NULL THEN ws.ws_net_paid ELSE 0 END) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
    GROUP BY c.c_customer_sk
),
SalesBreakdown AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
PopularItems AS (
    SELECT 
        sb.ws_item_sk,
        sb.total_quantity,
        sb.total_sales,
        sb.total_orders,
        RANK() OVER (ORDER BY sb.total_sales DESC) AS sales_rank
    FROM SalesBreakdown sb
    WHERE sb.total_quantity > 0
),
ItemPromotions AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),
DetailedSales AS (
    SELECT 
        pi.sales_rank,
        pi.total_sales,
        ci.total_spent,
        ci.order_count,
        ip.p_promo_name
    FROM PopularItems pi
    LEFT JOIN CustomerSpending ci ON pi.ws_item_sk = ci.c_customer_sk
    LEFT JOIN ItemPromotions ip ON pi.ws_item_sk = ip.p_promo_id
    WHERE pi.sales_rank <= 100
)
SELECT 
    ds.sales_rank,
    ds.total_sales,
    ds.total_spent,
    COALESCE(ds.order_count, 0) AS order_count,
    COALESCE(ds.p_promo_name, 'No Promotion') AS promo_name
FROM DetailedSales ds
ORDER BY ds.sales_rank;
