
WITH RECURSIVE customer_sales_rank AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_sales,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(ws.ws_net_paid), 0) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
income_bracket AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN ib.ib_income_band_sk IS NOT NULL THEN 'In Income Band'
            ELSE 'No Income Band'
        END AS income_status
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
date_filter AS (
    SELECT 
        d.d_date_sk
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
store_summary AS (
    SELECT 
        s.s_store_sk, 
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM 
        store s
    LEFT JOIN 
        store_sales cs ON s.s_store_sk = cs.ss_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    cs.customer_sk,
    cs.total_sales,
    cs.sales_rank,
    ib.income_status,
    ds.d_date_sk,
    ss.total_orders,
    ss.avg_sales_price,
    ss.total_net_profit
FROM 
    customer_sales_rank cs
JOIN 
    income_bracket ib ON cs.c_customer_sk = ib.cd_demo_sk 
CROSS JOIN 
    (SELECT * FROM date_filter) ds
LEFT JOIN 
    store_summary ss ON ds.d_date_sk IN (SELECT DISTINCT ss_sold_date_sk FROM store_sales)
WHERE 
    (ss.total_orders > 0 AND ss.avg_sales_price IS NOT NULL)
    OR 
    (ib.income_status = 'No Income Band' AND cs.sales_rank <= 10)
ORDER BY 
    cs.sales_rank, 
    ss.total_net_profit DESC NULLS LAST;
