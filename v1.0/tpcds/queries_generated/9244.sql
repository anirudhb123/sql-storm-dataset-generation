
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WarehouseData AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(DISTINCT s.s_store_sk) AS total_stores
    FROM 
        warehouse w
    JOIN 
        store s ON w.w_warehouse_sk = s.s_division_id
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    sd.ws_sold_date_sk,
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    wd.total_stores
FROM 
    SalesData sd
JOIN 
    CustomerData cd ON cd.c_customer_sk IN (
        SELECT 
            ws.ws_bill_customer_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_item_sk = sd.ws_item_sk
    )
JOIN 
    WarehouseData wd ON wd.w_warehouse_sk IN (
        SELECT 
            ws.ws_warehouse_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_item_sk = sd.ws_item_sk
    )
ORDER BY 
    sd.total_sales DESC
LIMIT 100;
