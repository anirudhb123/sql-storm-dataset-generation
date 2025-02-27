
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        COALESCE(c.c_gender, 'UNKNOWN') AS customer_gender,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sale_rank
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30
                          AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_customer_sk, c.c_gender
),
TopCustomers AS (
    SELECT 
        customer_gender,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY customer_gender ORDER BY total_sales DESC) AS gender_rank
    FROM 
        RankedSales
)
SELECT 
    tc.customer_gender,
    tc.total_sales,
    (SELECT COUNT(DISTINCT ws_bill_customer_sk) FROM web_sales) AS total_customers,
    (SELECT AVG(total_sales) FROM TopCustomers) AS avg_sales,
    (SELECT COUNT(*) FROM TopCustomers WHERE gender_rank <= 5) AS top_customers_count
FROM 
    TopCustomers tc
WHERE 
    tc.gender_rank <= 10
ORDER BY 
    total_sales DESC;

WITH InventoryLevels AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_quantity,
        RANK() OVER (ORDER BY SUM(inv_quantity_on_hand) DESC) AS quantity_rank
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
)

SELECT
    w.w_warehouse_id,
    IL.total_quantity,
    COALESCE(NULLIF(w.w_city, ''), 'UNKNOWN CITY') AS warehouse_city,
    CASE
        WHEN IL.total_quantity > 1000 THEN 'HIGH'
        WHEN IL.total_quantity BETWEEN 500 AND 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS stock_level
FROM 
    Warehouse w
LEFT JOIN 
    InventoryLevels IL ON w.w_warehouse_sk = IL.inv_warehouse_sk
WHERE 
    IL.quantity_rank <= 5
ORDER BY 
    total_quantity DESC;
