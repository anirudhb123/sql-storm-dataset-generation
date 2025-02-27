
WITH AddressInfo AS (
    SELECT 
        ca.city AS City, 
        ca.state AS State, 
        CONCAT(ca.street_number, ' ', ca.street_name, ' ', ca.street_type) AS Full_Address,
        ca.country AS Country
    FROM 
        customer_address ca
),
CustomerStats AS (
    SELECT 
        CASE 
            WHEN cd.gender = 'F' THEN 'Female' 
            ELSE 'Male' 
        END AS Gender,
        COUNT(DISTINCT c.c_customer_sk) AS Total_Customers,
        AVG(cd.purchase_estimate) AS Avg_Purchase_Estimate,
        SUM(cd.dep_count) AS Total_Dep_Count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        CASE 
            WHEN cd.gender = 'F' THEN 'Female' 
            ELSE 'Male' 
        END
),
SalesByWarehouse AS (
    SELECT 
        w.w_warehouse_name AS Warehouse_Name,
        SUM(ws.ws_ext_sales_price) AS Total_Sales,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Orders
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_name
)
SELECT 
    ai.City, 
    ai.State, 
    ai.Full_Address, 
    ai.Country,
    cs.Gender,
    cs.Total_Customers,
    cs.Avg_Purchase_Estimate,
    cs.Total_Dep_Count,
    sw.Warehouse_Name,
    sw.Total_Sales,
    sw.Total_Orders
FROM 
    AddressInfo ai
CROSS JOIN 
    CustomerStats cs
CROSS JOIN 
    SalesByWarehouse sw
ORDER BY 
    ai.City, cs.Gender, sw.Total_Sales DESC;
