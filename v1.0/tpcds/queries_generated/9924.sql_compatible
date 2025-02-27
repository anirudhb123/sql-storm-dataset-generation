
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND cd.cd_education_status IN ('Bachelors', 'Masters')
    GROUP BY 
        ws.web_site_id
),
TopSales AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders
    FROM 
        RankedSales
    WHERE 
        rank <= 5
)
SELECT 
    ts.web_site_id,
    ts.total_sales,
    ts.total_orders,
    w.w_warehouse_name,
    AVG(i.i_current_price) AS average_item_price,
    COUNT(DISTINCT ws.ws_item_sk) AS total_items_sold
FROM 
    TopSales ts
JOIN 
    web_sales ws ON ts.web_site_id = ws.ws_web_site_id
JOIN 
    inventory i ON ws.ws_item_sk = i.inv_item_sk
JOIN 
    warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
GROUP BY 
    ts.web_site_id, ts.total_sales, ts.total_orders, w.w_warehouse_name
ORDER BY 
    ts.total_sales DESC;
