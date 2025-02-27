
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WarehouseSales AS (
    SELECT 
        ws.warehouse_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_value
    FROM 
        web_sales ws
    GROUP BY 
        ws.warehouse_sk
),
PopularItems AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_value
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cr.total_returns,
    cr.total_return_amount,
    w.total_quantity_sold AS total_sold_in_warehouse,
    pi.total_quantity_sold AS popular_item_quantity,
    pi.total_sales_value AS popular_item_value
FROM 
    CustomerDemographics cd
JOIN 
    CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
LEFT JOIN 
    WarehouseSales w ON cd.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_quantity > 0)
LEFT JOIN 
    PopularItems pi ON cd.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = pi.ws_item_sk)
WHERE 
    cr.total_return_amount > 1000
ORDER BY 
    cr.total_return_amount DESC;
