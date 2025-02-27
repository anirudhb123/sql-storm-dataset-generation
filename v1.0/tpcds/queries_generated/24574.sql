
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk IN (
            SELECT 
                d_date_sk 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023 AND 
                d_moy IN (5, 6) AND 
                d_weekend = 'Y'
        )
),
top_sales AS (
    SELECT 
        rs.web_site_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        ranked_sales rs
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.web_site_sk
),
customer_stats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_net_profit) AS max_profit,
        MIN(ws.ws_net_profit) AS min_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
customer_income AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(*) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        hd.hd_demo_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
sales_summary AS (
    SELECT 
        cs.c_customer_id,
        ci.ib_lower_bound,
        ci.ib_upper_bound,
        cs.order_count,
        cs.max_profit,
        cs.min_profit
    FROM 
        customer_stats cs
    LEFT JOIN 
        customer_income ci ON cs.c_customer_id = ci.hd_demo_sk
),
final_report AS (
    SELECT 
        ts.web_site_sk, 
        ts.total_quantity, 
        ts.total_net_profit, 
        COALESCE(ss.order_count, 0) AS total_orders,
        COALESCE(ss.max_profit, 0) AS highest_profit,
        COALESCE(ss.min_profit, 0) AS lowest_profit
    FROM 
        top_sales ts
    LEFT JOIN 
        sales_summary ss ON ts.web_site_sk = ss.c_customer_id
)
SELECT 
    fr.web_site_sk,
    fr.total_quantity,
    fr.total_net_profit,
    fr.total_orders,
    fr.highest_profit,
    fr.lowest_profit,
    CASE 
        WHEN fr.total_net_profit IS NULL THEN 'No Profit'
        WHEN fr.total_net_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status,
    COALESCE(ROUND(AVG(total_net_profit), 2), 0) OVER (PARTITION BY fr.web_site_sk) AS avg_net_profit
FROM 
    final_report fr
ORDER BY 
    fr.total_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
