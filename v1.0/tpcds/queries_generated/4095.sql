
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
sales_summary AS (
    SELECT 
        r.web_site_sk,
        MAX(r.total_quantity) AS max_quantity,
        MAX(r.total_net_paid) AS max_net_paid
    FROM 
        ranked_sales r
    WHERE 
        r.rank <= 5
    GROUP BY 
        r.web_site_sk
),
sales_analysis AS (
    SELECT 
        w.w_warehouse_name,
        COALESCE(s.max_quantity, 0) AS max_quantity,
        COALESCE(s.max_net_paid, 0) AS max_net_paid,
        CASE 
            WHEN COALESCE(s.max_net_paid, 0) > 0 THEN ROUND(COALESCE(s.max_quantity, 0) / NULLIF(s.max_net_paid, 0), 2)
            ELSE NULL 
        END AS quantity_per_dollar
    FROM 
        warehouse w
    LEFT JOIN 
        sales_summary s ON w.w_warehouse_sk = s.web_site_sk
)
SELECT 
    w.w_warehouse_name,
    COALESCE(s.max_quantity, 0) AS max_quantity,
    COALESCE(s.max_net_paid, 0) AS max_net_paid,
    COALESCE(s.quantity_per_dollar, 0) AS quantity_per_dollar
FROM 
    sales_summary s
RIGHT JOIN 
    warehouse w ON s.web_site_sk = w.w_warehouse_sk
WHERE 
    w.w_warehouse_name IS NOT NULL
ORDER BY 
    quantity_per_dollar DESC
LIMIT 10;
