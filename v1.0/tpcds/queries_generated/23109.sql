
WITH CustomerProfit AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL AND (c.c_birth_month BETWEEN 1 AND 12)
    GROUP BY 
        c.c_customer_id
),
OverPromotedCustomers AS (
    SELECT 
        cp.c_customer_id,
        cp.total_profit,
        cp.total_orders,
        cp.avg_order_value,
        DENSE_RANK() OVER (ORDER BY cp.total_profit DESC) AS rank_profit
    FROM 
        CustomerProfit cp
    WHERE 
        cp.avg_order_value IS NOT NULL AND cp.total_orders > 10
),
TopLocations AS (
    SELECT 
        c.c_current_addr_sk,
        COUNT(DISTINCT ws.ws_order_number) AS cnt_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_current_addr_sk
    ORDER BY 
        cnt_orders DESC
    LIMIT 1
)
SELECT 
    o.c_customer_id,
    o.total_profit,
    o.total_orders,
    o.avg_order_value,
    COALESCE(t.cnt_orders, 0) AS order_count_at_top_location,
    CASE 
        WHEN o.rank_profit <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS promotion_category
FROM 
    OverPromotedCustomers o
LEFT JOIN 
    TopLocations t ON o.c_customer_id IN (SELECT c.c_customer_id
                                            FROM customer c
                                            WHERE c.c_current_addr_sk = t.c_current_addr_sk)
WHERE 
    o.total_profit > (
        SELECT AVG(total_profit) FROM CustomerProfit
    ) OR o.total_orders > (SELECT AVG(total_orders) FROM CustomerProfit)
ORDER BY 
    o.total_profit DESC;
