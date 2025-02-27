
WITH CustomerOrderMetrics AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        MAX(ws.ws_net_paid_inc_tax) AS max_payment,
        MIN(ws.ws_net_paid_inc_tax) AS min_payment
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighValueCustomers AS (
    SELECT 
        com.c_customer_id
    FROM 
        CustomerOrderMetrics com
    WHERE 
        com.total_sales > 10000 AND com.total_orders > 5
),
PromotionsUsed AS (
    SELECT 
        ws.ws_order_number,
        COUNT(DISTINCT ws.ws_promo_sk) AS total_promotions
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
),
HighPromoOrders AS (
    SELECT 
        pu.ws_order_number,
        pu.total_promotions
    FROM 
        PromotionsUsed pu
    WHERE 
        pu.total_promotions > 2
)
SELECT 
    c.c_customer_id,
    com.total_orders,
    com.total_sales,
    com.avg_net_profit,
    com.max_payment,
    com.min_payment,
    COALESCE(hp.total_promotions, 0) AS high_promo_count
FROM 
    CustomerOrderMetrics com
JOIN 
    HighValueCustomers hc ON com.c_customer_id = hc.c_customer_id
LEFT JOIN 
    HighPromoOrders hp ON com.c_customer_id IN (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_order_number = hp.ws_order_number)
ORDER BY 
    com.total_sales DESC
LIMIT 100;
