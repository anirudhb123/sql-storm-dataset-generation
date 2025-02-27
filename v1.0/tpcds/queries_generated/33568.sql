
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_income_band_sk, hd.hd_income_band_sk) AS income_band,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, income_band
),
customer_ranks AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY income_band ORDER BY total_profit DESC) AS profit_rank,
        DENSE_RANK() OVER (ORDER BY total_orders DESC) AS order_rank
    FROM 
        sales_hierarchy
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ch.total_orders,
    ch.total_profit,
    COALESCE(ch.profit_rank, 0) AS rank_with_null,
    CASE 
        WHEN ch.profit_rank = 1 THEN 'Top Performer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    customer_ranks ch
LEFT JOIN 
    income_band ib ON ch.income_band = ib.ib_income_band_sk
WHERE 
    ch.total_profit > 0
    AND EXISTS (
        SELECT 1 
        FROM store_sales ss
        WHERE 
            ss.ss_customer_sk = ch.c_customer_sk 
            AND ss.ss_sales_price > 50
    )
ORDER BY 
    ch.total_profit DESC, 
    ch.total_orders DESC
LIMIT 100;
