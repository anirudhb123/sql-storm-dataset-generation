
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WarehouseData AS (
    SELECT 
        w.w_warehouse_id,
        CONCAT(w.w_street_number, ' ', w.w_street_name, ' ', w.w_street_type, ', ', w.w_city, ', ', w.w_state, ' ', w.w_zip) AS full_address,
        w.w_country
    FROM 
        warehouse w
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_bill_customer_sk,
        ws.ws_ship_date_sk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN 20220101 AND 20221231
),
AggregatedSales AS (
    SELECT 
        sd.ws_bill_customer_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_ext_sales_price) AS total_sales
    FROM 
        SalesData sd
    GROUP BY 
        sd.ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    wd.w_warehouse_id,
    wd.full_address,
    asd.total_quantity,
    asd.total_sales
FROM 
    CustomerData cd
JOIN 
    AggregatedSales asd ON cd.c_customer_id = asd.ws_bill_customer_sk
LEFT JOIN 
    WarehouseData wd ON wd.w_warehouse_id = (SELECT w.w_warehouse_id FROM warehouse w ORDER BY RANDOM() LIMIT 1)
ORDER BY 
    asd.total_sales DESC
LIMIT 100;
