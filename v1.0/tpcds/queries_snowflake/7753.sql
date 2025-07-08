
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws_sold_date_sk,
        ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        c.c_first_name,
        c.c_last_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    s.ws_sold_date_sk,
    i.i_item_id,
    SUM(s.total_quantity) AS total_quantity_sold,
    SUM(s.total_sales) AS total_sales,
    SUM(s.total_net_paid) AS total_net_paid,
    MAX(cd.cd_gender) AS customer_gender,
    MAX(cd.cd_marital_status) AS customer_marital_status,
    MAX(cd.cd_education_status) AS customer_education_status
FROM 
    SalesData s
JOIN 
    item i ON s.ws_item_sk = i.i_item_sk
JOIN 
    CustomerData cd ON cd.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_sold_date_sk = s.ws_sold_date_sk)
GROUP BY 
    s.ws_sold_date_sk,
    i.i_item_id
ORDER BY 
    total_sales DESC
LIMIT 100;
