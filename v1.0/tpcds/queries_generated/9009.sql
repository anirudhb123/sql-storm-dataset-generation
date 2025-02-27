
WITH SalesAggregates AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(SA.total_sales) AS total_sales_by_demographic
    FROM 
        SalesAggregates SA
    JOIN 
        customer c ON c.c_customer_sk = (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_ext_sales_price = SA.total_sales LIMIT 1) 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
),
SalesByWarehouse AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    CD.cd_gender,
    CD.cd_marital_status,
    CD.cd_education_status,
    CD.total_sales_by_demographic,
    W.warehouse_sales,
    R.r_reason_desc
FROM 
    CustomerDemographics CD
JOIN 
    SalesByWarehouse W ON 1=1
JOIN 
    reason R ON R.r_reason_sk = (SELECT MIN(sr_reason_sk) FROM store_returns sr WHERE sr_return_quantity > 0)
ORDER BY 
    CD.total_sales_by_demographic DESC, 
    W.warehouse_sales DESC;
