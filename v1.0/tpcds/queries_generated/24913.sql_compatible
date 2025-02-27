
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) as rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > 0
), 
CustomerActivity AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        ca.c_customer_sk, 
        ca.order_count, 
        ca.total_profit,
        RANK() OVER (ORDER BY ca.total_profit DESC) AS profit_rank
    FROM 
        CustomerActivity ca
    WHERE 
        ca.order_count > 5
)
SELECT 
    wa.w_warehouse_id,
    sm.sm_ship_mode_id,
    MAX(rs.ws_net_profit) AS max_profit,
    COALESCE(tc.order_count, 0) AS customer_order_count,
    CASE 
        WHEN tc.total_profit IS NULL THEN 'No Orders'
        ELSE 'Orders Placed'
    END AS order_status
FROM 
    warehouse wa
JOIN 
    ship_mode sm ON wa.w_warehouse_sk = sm.sm_ship_mode_sk
LEFT JOIN 
    RankedSales rs ON rs.ws_order_number IN (SELECT DISTINCT ws_order_number FROM web_sales WHERE ws_net_profit IS NOT NULL)
LEFT JOIN 
    TopCustomers tc ON tc.c_customer_sk = rs.web_site_sk
WHERE 
    wa.w_country = 'USA' AND rs.rank_profit <= 10
GROUP BY 
    wa.w_warehouse_id, sm.sm_ship_mode_id, tc.order_count, tc.total_profit
HAVING 
    MAX(rs.ws_net_profit) IS NOT NULL OR COUNT(tc.c_customer_sk) > 2
ORDER BY 
    max_profit DESC, customer_order_count ASC;
