
WITH sales_data AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws 
    LEFT JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk 
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY 
        ws.web_site_id
),
returns_data AS (
    SELECT 
        wr.wr_web_page_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(wr.wr_order_number) AS total_returns
    FROM 
        web_returns wr 
    LEFT JOIN 
        web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk 
    GROUP BY 
        wr.wr_web_page_sk
)
SELECT 
    sd.web_site_id, 
    sd.total_sales, 
    rd.total_return_amt, 
    (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return_amt, 0)) AS net_revenue,
    sd.total_orders,
    CASE 
        WHEN sd.sales_rank = 1 THEN 'Top Seller'
        WHEN sd.sales_rank <= 3 THEN 'Top 3'
        ELSE 'Other'
    END AS sales_category
FROM 
    sales_data sd
FULL OUTER JOIN 
    returns_data rd ON sd.web_site_id = rd.wr_web_page_sk
WHERE 
    (sd.total_sales IS NOT NULL OR rd.total_return_amt IS NOT NULL)
ORDER BY 
    net_revenue DESC
LIMIT 100;
