
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ss.store_sk,
        SUM(ss.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.store_sk ORDER BY SUM(ss.net_profit) DESC) AS profit_rank
    FROM store_sales ss
    WHERE ss.sold_date_sk BETWEEN 2400 AND 2600
    GROUP BY ss.store_sk
),
customer_education AS (
    SELECT 
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
    GROUP BY cd.cd_education_status
),
promotion_summary AS (
    SELECT 
        p.promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS promo_sales_count,
        SUM(ws.ws_net_profit) AS total_promo_profit
    FROM promotion p
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY p.promo_id
),
serious_customers AS (
    SELECT 
        cu.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM customer cu
    JOIN web_sales ws ON cu.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk >= 2400
    GROUP BY cu.c_customer_id
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT 
    a.ca_city,
    a.ca_state,
    COALESCE(sh.total_net_profit, 0) AS total_store_profit,
    COALESCE(ec.customer_count, 0) AS total_customers,
    COALESCE(ps.promo_sales_count, 0) AS sales_count,
    COALESCE(sc.total_profit, 0) AS serious_customer_profit
FROM customer_address a
FULL OUTER JOIN sales_hierarchy sh ON a.ca_address_sk = sh.store_sk
FULL OUTER JOIN customer_education ec ON TRUE
FULL OUTER JOIN promotion_summary ps ON TRUE
FULL OUTER JOIN serious_customers sc ON TRUE
WHERE a.ca_state IN ('NY', 'CA')
ORDER BY total_store_profit DESC,
         total_customers DESC,
         sales_count DESC;
