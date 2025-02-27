
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2022
    GROUP BY ws.web_site_sk, ws.web_name, ws.ws_order_number
),
top_sales AS (
    SELECT 
        web_site_sk,
        web_name,
        total_quantity,
        total_sales
    FROM ranked_sales
    WHERE sales_rank = 1
),
store_info AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COALESCE(NULLIF(SUM(sr.sr_return_quantity), 0), 1) AS effective_return_quantity
    FROM store s
    LEFT JOIN store_returns sr ON s.s_store_sk = sr.s_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
)
SELECT 
    ti.web_name,
    si.s_store_name,
    (ti.total_sales - si.total_return_amt) AS net_sales,
    ROUND(AVG(SUM(si.effective_return_quantity) / NULLIF(ti.total_quantity, 0)), 2) AS return_ratio,
    CASE 
        WHEN ROUND(AVG(SUM(si.effective_return_quantity) / NULLIF(ti.total_quantity, 0)), 2) > 0.5 THEN 'High Returns'
        WHEN ROUND(AVG(SUM(si.effective_return_quantity) / NULLIF(ti.total_quantity, 0)), 2) BETWEEN 0.2 AND 0.5 THEN 'Moderate Returns'
        ELSE 'Low Returns'
    END AS return_status
FROM top_sales ti
JOIN store_info si ON ti.web_site_sk = si.s_store_sk
GROUP BY ti.web_name, si.s_store_name
HAVING net_sales > 1000
ORDER BY net_sales DESC, return_ratio DESC
LIMIT 10;
