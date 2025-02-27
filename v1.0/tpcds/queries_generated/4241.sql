
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        sd.c_demo_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics sd ON c.c_current_cdemo_sk = sd.cd_demo_sk
    GROUP BY 
        ws.web_site_id, sd.c_demo_sk
),
top_sales AS (
    SELECT 
        web_site_id, 
        total_sales, 
        total_orders
    FROM 
        sales_summary
    WHERE 
        sales_rank <= 10
),
return_summary AS (
    SELECT 
        w.web_site_id,
        SUM(wr.wr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns
    FROM 
        web_returns wr
    INNER JOIN 
        web_sales ws ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
    INNER JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        w.web_site_id
)
SELECT 
    ts.web_site_id,
    ts.total_sales,
    ts.total_orders,
    COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(rs.total_returns, 0) AS total_returns,
    (ts.total_sales - COALESCE(rs.total_returned_amount, 0)) AS net_sales
FROM 
    top_sales ts
LEFT JOIN 
    return_summary rs ON ts.web_site_id = rs.web_site_id
ORDER BY 
    net_sales DESC;
