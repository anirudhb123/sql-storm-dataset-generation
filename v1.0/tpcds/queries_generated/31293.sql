
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
top_sales AS (
    SELECT 
        web_site_id,
        total_profit,
        total_orders
    FROM 
        sales_summary
    WHERE 
        rank <= 5
),
date_filtered_sales AS (
    SELECT 
        d.d_date,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_net_paid
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_date BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY 
        d.d_date
),
income_band_summary AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(c.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        household_demographics hd
    JOIN 
        customer_demographics c ON hd.hd_demo_sk = c.cd_demo_sk
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)

SELECT 
    t.web_site_id,
    t.total_profit,
    t.total_orders,
    d.total_net_paid,
    ibs.customer_count,
    ibs.avg_purchase_estimate
FROM 
    top_sales t
JOIN 
    date_filtered_sales d ON t.web_site_id IN (
        SELECT 
            ws.web_site_id 
        FROM 
            web_sales ws
        WHERE 
            ws.ws_net_paid > 100
    )
JOIN 
    income_band_summary ibs ON ibs.customer_count > 50
ORDER BY 
    t.total_profit DESC, d.total_net_paid DESC;
