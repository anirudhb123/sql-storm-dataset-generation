
WITH SalesData AS (
    SELECT 
        ws_bill_addr_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT ws_item_sk) AS item_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_bill_addr_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesWithDemographics AS (
    SELECT 
        sd.ws_bill_addr_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        sd.total_sales,
        sd.order_count,
        sd.item_count
    FROM 
        SalesData sd
    JOIN 
        CustomerDemographics cd ON sd.ws_bill_addr_sk = c.c_current_addr_sk
)
SELECT 
    cd_gender,
    cd_marital_status,
    AVG(total_sales) AS avg_sales,
    AVG(order_count) AS avg_orders,
    AVG(item_count) AS avg_items
FROM 
    SalesWithDemographics
GROUP BY 
    cd_gender, cd_marital_status
ORDER BY 
    avg_sales DESC;
