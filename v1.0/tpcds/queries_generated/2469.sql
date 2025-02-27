
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_site ws_data ON ws.ws_web_site_sk = ws_data.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 3) 
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023 AND d_moy = 3)
    GROUP BY 
        ws.web_site_id
),
TopWebSites AS (
    SELECT 
        web_site_id,
        total_quantity,
        total_profit
    FROM 
        RankedSales 
    WHERE 
        rank <= 5
)
SELECT 
    w.web_site_id,
    COALESCE(tb.total_quantity, 0) AS quantity_sold,
    COALESCE(tb.total_profit, 0) AS profit,
    CASE 
        WHEN COALESCE(tb.total_quantity, 0) = 0 THEN 'No Sales'
        ELSE 'Sales Made'
    END AS sales_status,
    (SELECT COUNT(DISTINCT ws.order_number) 
     FROM web_sales ws 
     WHERE ws.ws_web_site_sk = w.web_site_sk AND ws.ws_sales_price > 100) AS high_value_orders
FROM 
    web_site w
LEFT JOIN 
    TopWebSites tb ON w.web_site_id = tb.web_site_id
ORDER BY 
    tb.total_profit DESC NULLS LAST;
