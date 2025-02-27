
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_ship_tax) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_ship_tax) DESC) AS rank_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        r.ws_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.total_spent,
        r.total_orders
    FROM 
        RankedSales r
    JOIN 
        customer c ON r.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        r.rank_sales <= 10
),
PromotionalPerformance AS (
    SELECT 
        p.p_promo_id,
        COUNT(ws_order_number) AS promo_order_count,
        SUM(ws_net_paid_inc_tax) AS promo_total_revenue
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_id
),
CustomerMetrics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.total_orders,
    COALESCE(pm.promo_order_count, 0) AS promo_order_count,
    COALESCE(pm.promo_total_revenue, 0) AS promo_total_revenue,
    cm.cd_gender,
    cm.customer_count,
    cm.avg_purchase_estimate
FROM 
    TopCustomers tc
LEFT JOIN 
    PromotionalPerformance pm ON tc.total_orders > 0
LEFT JOIN 
    CustomerMetrics cm ON tc.ws_bill_customer_sk = (SELECT DISTINCT c.c_customer_sk FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL)
WHERE 
    tc.total_spent > (SELECT AVG(total_spent) FROM RankedSales)
ORDER BY 
    tc.total_spent DESC;
