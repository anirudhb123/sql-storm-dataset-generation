
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.sold_date_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy BETWEEN 1 AND 3
    GROUP BY 
        ws.web_site_sk, ws.sold_date_sk
),
top_web_sites AS (
    SELECT 
        web_site_sk,
        total_sales,
        total_orders
    FROM 
        ranked_sales
    WHERE 
        rank <= 10
)
SELECT 
    w.web_site_id,
    w.web_name,
    tws.total_sales,
    tws.total_orders,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(inv.inv_quantity_on_hand) AS total_inventory
FROM 
    top_web_sites tws
JOIN 
    web_site w ON tws.web_site_sk = w.web_site_sk
JOIN 
    customer_demographics cd ON cd.cd_demo_sk IN (
        SELECT c.c_current_cdemo_sk 
        FROM customer c 
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        WHERE ws.web_site_sk = tws.web_site_sk
    )
JOIN 
    inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
GROUP BY 
    w.web_site_id, w.web_name, tws.total_sales, tws.total_orders
ORDER BY 
    tws.total_sales DESC;
