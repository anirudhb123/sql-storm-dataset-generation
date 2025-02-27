
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, ws.web_name
), 
top_sales AS (
    SELECT 
        ws.web_site_id,
        rs.total_sales,
        ca.ca_city,
        ca.ca_state,
        ra.num_returns
    FROM 
        ranked_sales rs
    JOIN 
        web_site ws ON rs.web_site_sk = ws.web_site_sk
    LEFT JOIN 
        (SELECT 
            wr.web_site_sk,
            COUNT(wr.wr_order_number) AS num_returns
         FROM 
            web_returns wr 
         GROUP BY 
            wr.web_site_sk) ra ON ws.web_site_sk = ra.web_site_sk
    LEFT JOIN 
        customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = ws.web_site_sk)
    WHERE 
        rs.sales_rank <= 5
)
SELECT 
    ts.web_site_id,
    ts.total_sales,
    COALESCE(ts.num_returns, 0) AS num_returns,
    ROUND((ts.total_sales / NULLIF(ts.num_returns, 0)), 2) AS revenue_per_return,
    CASE 
        WHEN ts.num_returns IS NULL THEN 'No Returns'
        WHEN ts.num_returns > 100 THEN 'High Returns'
        ELSE 'Normal Returns'
    END AS return_category
FROM 
    top_sales ts
ORDER BY 
    ts.total_sales DESC;
