
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_count,
        SUM(wr.wr_return_amt_inc_tax) AS total_web_return_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
),
PromotionalImpact AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
),
DailySales AS (
    SELECT
        dd.d_date,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM
        date_dim dd
    LEFT JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        catalog_sales cs ON dd.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        store_sales ss ON dd.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        dd.d_date
)
SELECT 
    cs.c_customer_sk,
    cs.return_count,
    cs.total_return_amount,
    cs.web_return_count,
    cs.total_web_return_amount,
    pi.p_promo_id,
    pi.total_web_sales,
    pi.total_web_profit,
    ds.d_date,
    ds.total_web_sales,
    ds.total_catalog_sales,
    ds.total_store_sales
FROM 
    CustomerStats cs
JOIN 
    PromotionalImpact pi ON cs.c_customer_sk = (SELECT c.c_customer_sk FROM customer c ORDER BY RANDOM() LIMIT 1)
JOIN 
    DailySales ds ON ds.d_date BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    cs.c_customer_sk, pi.total_web_profit DESC, ds.total_web_sales DESC
LIMIT 100;
