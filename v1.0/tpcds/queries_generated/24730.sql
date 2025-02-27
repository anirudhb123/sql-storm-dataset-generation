
WITH RankedSales AS (
    SELECT 
        w.warehouse_name,
        s.store_name,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY w.warehouse_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank,
        DENSE_RANK() OVER (PARTITION BY w.warehouse_sk, s.store_name ORDER BY ws.ws_order_number) AS order_density
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.warehouse_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        ws.ws_sales_price IS NOT NULL
        AND ws.ws_ext_sales_price > 100
),

TopSales AS (
    SELECT 
        warehouse_name, 
        store_name, 
        ws_order_number, 
        ws_ext_sales_price
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 3
),

CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returned
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk 
    GROUP BY 
        c.c_customer_id
    HAVING 
        total_returned > 0
),

SalesByCustomer AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_ext_sales_price IS NOT NULL
    GROUP BY 
        c.c_customer_id
    HAVING 
        total_orders > 5
)

SELECT 
    t.warehouse_name,
    t.store_name,
    c.c_customer_id,
    c.total_orders,
    ROUND(c.total_spent, 2) AS total_spent,
    COALESCE(r.total_returned, 0) AS total_returned,
    CASE 
        WHEN r.total_returned > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS has_returns
FROM 
    TopSales t
JOIN 
    SalesByCustomer c ON t.warehouse_name = (SELECT DISTINCT w.warehouse_name 
                                               FROM warehouse w 
                                               WHERE w.warehouse_sk = t.warehouse_sk)
LEFT JOIN 
    CustomerReturns r ON c.c_customer_id = r.c_customer_id
WHERE 
    c.total_spent > (SELECT AVG(total_spent) 
                     FROM SalesByCustomer)
ORDER BY 
    t.warehouse_name, c.total_spent DESC;
