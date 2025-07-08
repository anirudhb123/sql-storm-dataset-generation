
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_net_paid,
        ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
TopSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_quantity) AS total_quantity
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
SalesDetails AS (
    SELECT 
        ts.ws_sold_date_sk,
        ts.ws_item_sk,
        ts.total_net_paid,
        ts.total_quantity,
        i.i_item_desc,
        i.i_current_price,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        TopSales ts
    JOIN 
        item i ON ts.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        customer c ON c.c_customer_sk IN (SELECT ws_ship_customer_sk FROM web_sales WHERE ws_sold_date_sk = ts.ws_sold_date_sk AND ws_item_sk = ts.ws_item_sk)
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    d.d_date_id,
    sd.ws_item_sk,
    sd.i_item_desc,
    sd.total_net_paid,
    sd.total_quantity,
    sd.i_current_price,
    sd.cd_gender,
    sd.cd_marital_status
FROM 
    date_dim d
JOIN 
    SalesDetails sd ON d.d_date_sk = sd.ws_sold_date_sk
ORDER BY 
    d.d_date_sk, sd.total_net_paid DESC;
