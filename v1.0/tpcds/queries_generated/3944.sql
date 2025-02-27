
WITH ranked_sales AS (
    SELECT 
        ws.sold_date_sk,
        ws.wholesale_cost,
        ws.list_price,
        ws.sales_price,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.sold_date_sk DESC) as rn
    FROM 
        web_sales ws
    WHERE 
        ws.sales_price > 0
        AND ws.sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(CASE WHEN rs.rn = 1 THEN rs.net_profit ELSE 0 END) AS last_purchase_net_profit,
        COUNT(rs.rn) AS total_purchases
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        ranked_sales rs ON c.c_customer_sk = rs.bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
income_ranges AS (
    SELECT 
        hd.hd_demo_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NOT NULL AND ib.ib_upper_bound IS NOT NULL THEN CONCAT('$', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
            ELSE 'Unknown'
        END AS income_range
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.last_purchase_net_profit,
    cs.total_purchases,
    ir.income_range
FROM 
    customer_stats cs
LEFT JOIN 
    income_ranges ir ON cs.c_customer_sk = ir.hd_demo_sk
WHERE 
    (cs.last_purchase_net_profit > 100 OR cs.total_purchases > 5)
    AND cs.cd_gender IS NOT NULL
ORDER BY 
    cs.last_purchase_net_profit DESC, cs.total_purchases DESC;
