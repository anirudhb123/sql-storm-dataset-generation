
WITH SalesSummary AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_manager IS NOT NULL
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY 
        i.i_item_id
),
HighVolumeItems AS (
    SELECT 
        item_id,
        total_quantity,
        total_sales,
        order_count,
        ROW_NUMBER() OVER (ORDER BY total_quantity DESC) AS rank
    FROM 
        SalesSummary
    WHERE 
        total_quantity > 500
),
CustomerStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    hv.item_id,
    hv.total_quantity,
    hv.total_sales,
    cs.c_customer_id,
    cs.total_orders,
    cs.total_spent
FROM 
    HighVolumeItems hv
JOIN 
    CustomerStats cs ON hv.order_count > 10
WHERE 
    hv.rank <= 10
ORDER BY 
    hv.total_sales DESC, cs.total_spent DESC;
