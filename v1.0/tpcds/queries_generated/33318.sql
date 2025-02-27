
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(*) AS sales_count,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
        COUNT(DISTINCT w.web_site_sk) AS website_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_income_band_sk, cd.cd_marital_status, hd.hd_buy_potential
),
date_stats AS (
    SELECT 
        d_year,
        d_month_seq,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY d_year ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    JOIN 
        date_dim d ON ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d_year, d_month_seq
)
SELECT 
    s.store_name, 
    ss.total_sales,
    ci.cd_gender,
    ci.buy_potential,
    ds.total_orders,
    ds.total_profit
FROM 
    sales_summary ss
INNER JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN 
    customer_info ci ON ci.c_customer_sk IN (SELECT sr_customer_sk FROM store_returns WHERE sr_store_sk = ss.ss_store_sk)
LEFT JOIN 
    date_stats ds ON ds.total_orders > 10 AND ds.total_profit > 1000
WHERE 
    ss.total_sales > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY 
    ss.total_sales DESC, 
    ds.total_profit DESC
LIMIT 50;
