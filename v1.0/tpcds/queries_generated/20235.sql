
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn,
        COALESCE(SUM(ws.ws_sales_price) FILTER (WHERE ws.ws_ship_date_sk IS NOT NULL), 0) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS num_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
CustomerPerformance AS (
    SELECT 
        rc.c_customer_id,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.total_spent,
        CASE 
            WHEN rc.total_spent > 1000 THEN 'High Value'
            WHEN rc.total_spent BETWEEN 500 AND 1000 THEN 'Mid Value'
            ELSE 'Low Value'
        END AS value_segment,
        SUM(CASE WHEN ws.ws_ship_date_sk IS NULL THEN 1 ELSE 0 END) AS pending_orders,
        COUNT(ws.ws_order_number) AS completed_orders
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        web_sales ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        rc.rn = 1 AND 
        rc.cd_marital_status IN ('S', 'M')
    GROUP BY 
        rc.c_customer_id, rc.cd_gender, rc.cd_marital_status, rc.total_spent
),
PromotionPerformance AS (
    SELECT 
        p.p_promo_id,
        COUNT(ws.ws_order_number) AS promo_sales_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.p_start_date_sk < 20050 AND
        p.p_end_date_sk > 20030
    GROUP BY 
        p.p_promo_id
)
SELECT 
    cp.c_customer_id,
    cp.cd_gender,
    cp.value_segment,
    cp.pending_orders,
    cp.completed_orders,
    COALESCE(pp.promo_sales_count, 0) AS promo_sales_count,
    COALESCE(pp.total_profit, 0) AS total_profit,
    CASE 
        WHEN cp.pending_orders > 5 THEN 'Attention Needed'
        ELSE 'On Track'
    END AS customer_status
FROM 
    CustomerPerformance cp
OUTER JOIN 
    PromotionPerformance pp ON pp.promo_sales_count > 0
ORDER BY 
    cp.total_spent DESC, cp.c_customer_id;
