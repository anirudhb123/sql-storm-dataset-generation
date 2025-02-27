
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND dd.d_moy IN (11, 12)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        sd.order_count
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 10
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    si.ws_item_sk,
    si.total_quantity,
    si.total_sales,
    cd.purchase_rank
FROM 
    TopSellingItems si
JOIN 
    web_sales ws ON si.ws_item_sk = ws.ws_item_sk
JOIN 
    CustomerData cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
WHERE 
    cd.purchase_rank <= 20
ORDER BY 
    si.total_sales DESC, cd.purchase_rank;
