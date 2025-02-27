
WITH RECURSIVE CTE_Customer_Summary AS (
    SELECT c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status,
           cd.cd_education_status, cd.cd_purchase_estimate, 
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           SUM(ws.ws_sales_price) AS total_spent,
           NTILE(4) OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS income_quartile
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
),
CTE_Summary_By_State AS (
    SELECT ca.ca_state, SUM(total_spent) AS state_spending, COUNT(*) AS customer_count
    FROM CTE_Customer_Summary ccs
    JOIN customer c ON ccs.c_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
),
CTE_Promotional_Analysis AS (
    SELECT ws.ws_order_number, p.p_promo_id, COUNT(DISTINCT p.p_promo_name) AS promo_count,
           SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY ws.ws_order_number, p.p_promo_id
)
SELECT 
    ccs.c_customer_id,
    ccs.cd_gender,
    ccs.total_orders,
    ccs.total_spent,
    sb.state_spending,
    cbs.customer_count,
    COALESCE(promo.total_profit, 0) AS total_promo_profit,
    CASE 
        WHEN ccs.total_spent IS NULL THEN 'unknown'
        WHEN ccs.total_spent > 500 THEN 'high_spender'
        WHEN ccs.total_spent BETWEEN 100 AND 500 THEN 'medium_spender'
        ELSE 'low_spender'
    END AS spending_category,
    (SELECT AVG(total_spent) FROM CTE_Customer_Summary) AS avg_spending
FROM CTE_Customer_Summary ccs
LEFT JOIN CTE_Summary_By_State sb ON sb.state_spending > 10000
LEFT JOIN CTE_Promotional_Analysis promo ON promo.ws_order_number = ccs.total_orders
LEFT JOIN customer_address ca ON ca.ca_address_sk = ccs.c_customer_sk
WHERE ccs.cd_marital_status = 'M' 
  AND ccs.cd_education_status IN ('PhD', 'Masters')
  AND ccs.c_customer_sk IS NOT NULL 
  AND EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_customer_sk = ccs.c_customer_sk HAVING SUM(ss.ss_net_profit) > 0)
ORDER BY ccs.total_spent DESC, ccs.c_customer_id
LIMIT 50;
