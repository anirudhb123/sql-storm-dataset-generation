
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
        AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
),
TopSales AS (
    SELECT 
        item_sk,
        total_sales,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    d.d_date,
    ts.item_sk,
    ts.total_sales,
    ts.sales_rank,
    cd.cd_gender,
    cd.cd_education_status
FROM 
    TopSales ts
JOIN 
    date_dim d ON ts.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk IN (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = ts.item_sk LIMIT 1))
WHERE 
    ts.sales_rank <= 5
ORDER BY 
    d.d_date,
    ts.sales_rank;
