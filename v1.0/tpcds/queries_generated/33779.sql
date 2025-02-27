
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
Top_Orders AS (
    SELECT 
        so.ws_order_number,
        COUNT(*) AS item_count,
        SUM(so.ws_ext_sales_price) AS total_sales
    FROM 
        Sales_CTE so
    WHERE 
        so.rn = 1
    GROUP BY 
        so.ws_order_number
    HAVING 
        COUNT(*) > 5
),
Customer_Details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        SUM(COALESCE(ir.inv_quantity_on_hand, 0)) AS inventory_on_hand
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        inventory ir ON ir.inv_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
Ship_Info AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_ext_ship_cost) AS avg_ship_cost
    FROM 
        ship_mode sm
    JOIN 
        web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.inventory_on_hand,
    TO_CHAR(Total_Sales.total_sales, 'FM$999,999.00') AS formatted_total_sales,
    si.order_count,
    si.avg_ship_cost
FROM 
    Customer_Details cd
LEFT JOIN 
    Top_Orders Total_Sales ON Total_Sales.ws_order_number = (SELECT MAX(ws_order_number) FROM web_sales WHERE ws_bill_customer_sk = cd.c_customer_sk)
LEFT JOIN 
    Ship_Info si ON si.sm_ship_mode_id = (SELECT MAX(sm_ship_mode_id) FROM ship_mode)
WHERE 
    cd.inventory_on_hand > 100
ORDER BY 
    cd.cd_purchase_estimate DESC,
    cd.c_customer_id;
