
WITH total_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) as total_net_sales,
        COUNT(DISTINCT ws_order_number) as total_orders
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY ws_bill_customer_sk
),
customer_segmentation AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            WHEN cd.cd_purchase_estimate < 100 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END as purchase_segment
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        cs.ws_bill_customer_sk,
        SUM(cs.ws_net_profit) AS total_profit
    FROM (
        SELECT 
            cs_bill_customer_sk,
            cs_net_profit
        FROM catalog_sales
        WHERE cs_sold_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM web_sales)
    ) cs
    GROUP BY cs.ws_bill_customer_sk
    HAVING SUM(cs.ws_net_profit) > 5000
),
active_customer_segment AS (
    SELECT 
        csc.c_customer_sk,
        t.total_net_sales, 
        t.total_orders,
        hvc.total_profit
    FROM customer_segmentation csc
    LEFT JOIN total_sales t ON csc.c_customer_sk = t.ws_bill_customer_sk
    LEFT JOIN high_value_customers hvc ON csc.c_customer_sk = hvc.cs_bill_customer_sk
),
final_report AS (
    SELECT 
        acs.c_customer_sk,
        acs.total_net_sales,
        acs.total_orders,
        COALESCE(hvc.total_profit, 0) AS total_profit,
        SUM(ws_ext_discount_amt) OVER(PARTITION BY acs.c_customer_sk ORDER BY acs.total_orders DESC) AS cumulative_discounts
    FROM active_customer_segment acs
    LEFT JOIN web_sales ws ON acs.c_customer_sk = ws.ws_bill_customer_sk
    WHERE acs.total_orders IS NOT NULL
    ORDER BY acs.total_profit DESC
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(fr.total_net_sales, 0) AS total_net_sales,
    COALESCE(fr.total_orders, 0) AS total_orders,
    CASE 
        WHEN fr.total_profit IS NULL THEN 'Not A Contributor'
        WHEN fr.total_profit = 0 THEN 'Break-even'
        WHEN fr.total_profit > 0 AND fr.total_profit < 1000 THEN 'Minor Contributor'
        ELSE 'Major Contributor'
    END AS contribution_status,
    fr.cumulative_discounts
FROM final_report fr
JOIN customer c ON fr.c_customer_sk = c.c_customer_sk
WHERE fr.total_net_sales > 1000 OR fr.total_orders > 5
ORDER BY fr.total_profit DESC, c.c_last_name ASC
FETCH FIRST 100 ROWS ONLY;
