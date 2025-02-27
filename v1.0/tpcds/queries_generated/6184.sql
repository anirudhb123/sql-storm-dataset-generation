
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
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
ResultData AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.total_sales) AS total_sales,
        SUM(sd.total_discount) AS total_discount,
        SUM(sd.total_tax) AS total_tax,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        SalesData sd
    JOIN 
        web_site ws ON sd.ws_item_sk = ws.web_site_sk
    JOIN 
        CustomerData cd ON cd.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        sd.ws_item_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
)
SELECT 
    rd.ws_item_sk,
    rd.total_quantity,
    rd.total_sales,
    rd.total_discount,
    rd.total_tax,
    rd.cd_gender,
    rd.cd_marital_status,
    rd.cd_education_status,
    rd.cd_purchase_estimate,
    RANK() OVER (PARTITION BY rd.cd_gender ORDER BY rd.total_sales DESC) AS sales_rank
FROM 
    ResultData rd
ORDER BY 
    rd.cd_gender, rd.total_sales DESC
LIMIT 100;
