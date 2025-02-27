
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws.web_site_id
),
ItemSummary AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        i.i_item_id, i.i_product_name
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        item.total_quantity,
        item.total_net_paid,
        RANK() OVER (ORDER BY item.total_net_paid DESC) AS rank
    FROM 
        ItemSummary item
)
SELECT 
    ss.web_site_id,
    ss.total_quantity AS website_total_quantity,
    ss.total_net_paid AS website_total_net_paid,
    ti.i_item_id,
    ti.i_product_name,
    ti.total_quantity AS item_total_quantity,
    ti.total_net_paid AS item_total_net_paid
FROM 
    SalesSummary ss
JOIN 
    TopItems ti ON ss.total_quantity > 100
WHERE 
    ti.rank <= 10
ORDER BY 
    ss.web_site_id, ti.total_net_paid DESC;
