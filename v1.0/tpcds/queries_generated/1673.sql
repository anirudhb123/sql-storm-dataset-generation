
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
),
TopWebSites AS (
    SELECT 
        web_site_sk,
        total_quantity,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
WarehouseInventory AS (
    SELECT 
        inv.warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM 
        inventory inv
    GROUP BY 
        inv.warehouse_sk
),
SalesWithInventory AS (
    SELECT 
        tws.web_site_sk,
        tws.total_quantity,
        tws.total_sales,
        wi.total_stock
    FROM 
        TopWebSites tws
    LEFT JOIN 
        WarehouseInventory wi ON tws.web_site_sk = wi.warehouse_sk
)
SELECT 
    si.web_site_sk,
    si.total_quantity,
    si.total_sales,
    COALESCE(si.total_stock, 0) AS total_stock_available,
    CASE 
        WHEN si.total_stock < 100 THEN 'Low Stock'
        WHEN si.total_stock BETWEEN 100 AND 300 THEN 'Medium Stock'
        ELSE 'High Stock'
    END AS stock_status
FROM 
    SalesWithInventory si
WHERE 
    si.total_sales > (SELECT AVG(total_sales) * 1.5 FROM TopWebSites)
ORDER BY 
    si.total_sales DESC;
