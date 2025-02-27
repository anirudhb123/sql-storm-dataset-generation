
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        w.web_name,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_sk, w.web_name, ws_sold_date_sk
),
sales_returned AS (
    SELECT 
        wr.wr_returned_date_sk,
        SUM(wr_return_amt) AS total_returned_amt,
        COUNT(wr_order_number) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returned_date_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns_by_customer,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
sales_summary AS (
    SELECT 
        r.sales_rank,
        r.web_name,
        r.total_sales,
        r.order_count,
        COALESCE(s.total_returned_amt, 0) AS total_returns
    FROM 
        ranked_sales r
    LEFT JOIN 
        sales_returned s ON r.ws_sold_date_sk = s.wr_returned_date_sk
)
SELECT 
    ss.web_name,
    ss.total_sales,
    ss.order_count,
    ss.total_returns,
    cs.total_returns_by_customer,
    cs.total_spent,
    cs.cd_gender
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.web_name = (SELECT web_name FROM ranked_sales WHERE sales_rank = 1)
WHERE 
    ss.total_sales > 1000
    AND cs.total_returns_by_customer > 0
ORDER BY 
    ss.total_sales DESC;
