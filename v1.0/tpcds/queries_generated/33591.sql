
WITH RECURSIVE sales_data AS (
    SELECT
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY
        ws.web_site_sk, ws_sold_date_sk
),
ranked_sales AS (
    SELECT
        sd.web_site_sk,
        sd.ws_sold_date_sk,
        sd.total_quantity,
        sd.total_profit,
        RANK() OVER (PARTITION BY sd.web_site_sk ORDER BY sd.total_profit DESC) AS rank
    FROM 
        sales_data sd
)
SELECT 
    r.web_site_sk,
    COUNT(r.ws_sold_date_sk) AS sales_days,
    SUM(r.total_quantity) AS total_quantity_sold,
    AVG(r.total_profit) AS avg_profit_per_day,
    MAX(r.total_profit) AS max_daily_profit
FROM 
    ranked_sales r
JOIN 
    web_site w ON r.web_site_sk = w.web_site_sk
WHERE 
    r.rank <= 5
GROUP BY 
    r.web_site_sk
HAVING 
    SUM(r.total_quantity) > 100
ORDER BY 
    total_quantity_sold DESC;

-- Additional Query for stark comparison
SELECT
    w.web_site_id,
    COALESCE(t.total_sales, 0) AS total_sales,
    COALESCE(r.total_returned, 0) AS total_returned,
    COALESCE((t.total_sales - r.total_returned), 0) AS net_sales
FROM 
    web_site w
LEFT JOIN (
    SELECT
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
) t ON w.web_site_sk = t.web_site_sk
LEFT JOIN (
    SELECT
        wr.w_refunded_customer_sk,
        COUNT(wr.wr_order_number) AS total_returned
    FROM 
        web_returns wr
    GROUP BY 
        wr.w_refunded_customer_sk
) r ON w.web_site_sk = r.w_refunded_customer_sk
WHERE 
    w.web_open_date_sk < CURRENT_DATE -- Ensure the website is open
ORDER BY 
    net_sales DESC
LIMIT 10;
