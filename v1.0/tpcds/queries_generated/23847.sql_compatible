
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL AND
        ws.ws_sales_price > (SELECT AVG(ws_inner.ws_sales_price) 
                             FROM web_sales ws_inner 
                             WHERE ws_inner.ws_item_sk = ws.ws_item_sk)
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_profit) > 1000 AND
        COUNT(DISTINCT ws.ws_order_number) > 5
),
PopularItems AS (
    SELECT 
        i.i_item_id,
        COUNT(*) AS order_count
    FROM 
        item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
    HAVING 
        COUNT(*) > 10
),
SalesAnalysis AS (
    SELECT 
        rs.ws_order_number,
        i.i_item_id,
        rs.ws_sales_price,
        CASE 
            WHEN hs.total_orders IS NOT NULL THEN 'High Value Customer'
            ELSE 'Regular Customer'
        END AS customer_type,
        pi.order_count AS popular_item_flag,
        rs.price_rank
    FROM 
        RankedSales rs
    LEFT JOIN HighValueCustomers hs ON rs.ws_order_number = hs.c_customer_id
    LEFT JOIN PopularItems pi ON rs.ws_item_sk = pi.i_item_id
),
FinalReport AS (
    SELECT 
        sa.customer_type,
        COUNT(*) AS total_sales,
        AVG(sa.ws_sales_price) AS avg_sales_price,
        SUM(CASE WHEN sa.popular_item_flag IS NOT NULL THEN 1 ELSE 0 END) AS popular_items_sold,
        MAX(sa.price_rank) AS max_price_rank
    FROM 
        SalesAnalysis sa
    GROUP BY 
        sa.customer_type
)
SELECT 
    fr.customer_type,
    fr.total_sales,
    fr.avg_sales_price,
    fr.popular_items_sold,
    fr.max_price_rank
FROM 
    FinalReport fr
WHERE 
    fr.total_sales > 0
ORDER BY 
    fr.total_sales DESC;
