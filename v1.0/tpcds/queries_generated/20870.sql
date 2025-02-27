
WITH Customer_Summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        SUM(COALESCE(ws.ws_quantity, 0) + COALESCE(cs.cs_quantity, 0)) AS total_purchases,
        COUNT(DISTINCT ws.ws_order_number) as web_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) as store_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
Warehouse_Summary AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
),
Customer_Demo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    AND cd.cd_purchase_estimate IS NOT NULL
),
Highly_Active_Customers AS (
    SELECT 
        cs.full_name,
        cs.total_purchases,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cs.total_purchases DESC) as purchase_rank
    FROM Customer_Summary cs
    JOIN Customer_Demo cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE cs.total_purchases > (SELECT AVG(total_purchases) FROM Customer_Summary) 
),
Final_Report AS (
    SELECT 
        hac.full_name,
        hac.total_purchases,
        hac.cd_gender,
        wh.w_warehouse_name,
        wh.total_inventory,
        CASE 
            WHEN hac.purchase_rank <= 5 THEN 'Top Customer'
            ELSE 'Regular Customer'
        END AS customer_category
    FROM Highly_Active_Customers hac
    LEFT JOIN Warehouse_Summary wh ON wh.total_inventory > 100
)
SELECT 
    fr.full_name,
    fr.total_purchases,
    fr.cd_gender,
    fr.w_warehouse_name,
    fr.customer_category,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_first_name || ' ' || c.c_last_name = fr.full_name) AND sr.sr_return_quantity > 0) AS return_count
FROM Final_Report fr
WHERE fr.customer_category = 'Top Customer'
ORDER BY fr.total_purchases DESC
LIMIT 10;
