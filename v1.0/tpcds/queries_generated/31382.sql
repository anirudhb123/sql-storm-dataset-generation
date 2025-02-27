
WITH RECURSIVE revenue_with_ranks AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_revenue,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS revenue_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
customer_stats AS (
    SELECT 
        c.c_customer_id,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    cs.c_customer_id,
    COALESCE(cs.max_purchase_estimate, 0) AS max_purchase,
    COALESCE(cs.total_returns, 0) AS returns,
    COALESCE(cs.total_web_returns, 0) AS web_returns,
    rw.web_site_id,
    rw.total_revenue,
    rw.revenue_rank
FROM 
    customer_stats cs
CROSS JOIN 
    revenue_with_ranks rw
WHERE 
    (cs.max_purchase_estimate >= 500 AND cs.total_returns > cs.total_web_returns)
    OR (cs.max_purchase_estimate IS NULL AND rw.total_revenue > 10000)
ORDER BY 
    rw.total_revenue DESC, 
    cs.max_purchase DESC;
