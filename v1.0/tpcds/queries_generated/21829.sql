
WITH ranked_sales AS (
    SELECT 
        ws_c.customer_sk AS customer_id,
        ws_ws_promo_sk AS promo_id,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_c.customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN customer ws_c ON ws.ws_bill_customer_sk = ws_c.c_customer_sk
    LEFT JOIN promotion ws_p ON ws.ws_promo_sk = ws_p.p_promo_sk
    WHERE ws_net_paid_inc_ship > (
        SELECT AVG(ws_net_paid_inc_ship) 
        FROM web_sales 
        WHERE ws_ship_date_sk IS NOT NULL 
        GROUP BY ws_ship_date_sk
    )
    GROUP BY ws_c.customer_sk, ws.ws_promo_sk
),
customer_returns AS (
    SELECT 
        cr_returning_customer_sk AS customer_id,
        SUM(cr_return_amount) AS total_return_amount
    FROM catalog_returns
    WHERE cr_return_quantity > (
        SELECT AVG(cr_return_quantity) 
        FROM catalog_returns
    )
    GROUP BY cr_returning_customer_sk
),
final_metrics AS (
    SELECT 
        rs.customer_id,
        COALESCE(rs.total_net_profit, 0) AS total_net_profit,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(rs.total_net_profit, 0) = 0 THEN 'No Profit' 
            ELSE 'Profit' 
        END AS profit_status
    FROM ranked_sales rs
    FULL OUTER JOIN customer_returns cr ON rs.customer_id = cr.customer_id
)
SELECT 
    f.customer_id,
    f.total_net_profit,
    f.total_return_amount,
    f.profit_status,
    CASE 
        WHEN total_return_amount = 0 THEN 'All Sales'
        ELSE 'Returns Involved'
    END AS sales_status,
    CONCAT('Customer ', f.customer_id, ' has a total net profit of ', 
           TO_CHAR(f.total_net_profit, 'FM$999,999.00'), 
           ' and has returned items worth ', 
           TO_CHAR(f.total_return_amount, 'FM$999,999.00')) AS customer_summary
FROM final_metrics f
ORDER BY f.total_net_profit DESC NULLS LAST
LIMIT 10;
