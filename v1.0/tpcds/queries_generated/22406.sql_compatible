
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rn
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > (SELECT AVG(i_inner.i_current_price) FROM item AS i_inner WHERE i_inner.i_formulation IS NOT NULL)
    GROUP BY 
        ws.ws_item_sk
), 
top_sales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.total_quantity, 
        rs.total_revenue 
    FROM 
        ranked_sales AS rs
    WHERE 
        rs.rn = 1
), 
customer_counts AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
returns_summary AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned
    FROM 
        web_returns AS wr
    GROUP BY 
        wr.wr_item_sk
), 
final_summary AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_quantity,
        ts.total_revenue,
        COALESCE(rc.total_returned, 0) AS total_returned,
        cc.order_count
    FROM 
        top_sales AS ts
    LEFT JOIN 
        returns_summary AS rc ON ts.ws_item_sk = rc.wr_item_sk
    LEFT JOIN 
        customer_counts AS cc ON ts.ws_item_sk IN (SELECT ws.ws_item_sk FROM web_sales AS ws WHERE ws.ws_bill_customer_sk = cc.c_customer_sk)
)
SELECT 
    f.ws_item_sk,
    f.total_quantity,
    f.total_revenue,
    f.total_returned,
    CASE 
        WHEN f.total_returned > 0 THEN 'High Return Rate'
        ELSE 'Stable Sales'
    END AS stability_status,
    COALESCE(NULLIF(f.order_count, 0), 'No Orders') AS order_summary
FROM 
    final_summary AS f
WHERE 
    f.total_revenue > (SELECT AVG(total_revenue) FROM final_summary)
ORDER BY 
    f.total_revenue DESC;
