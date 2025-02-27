
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year AS year,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_ship_date_sk, ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        cr.returned_date_sk,
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.returned_date_sk, cr.cr_item_sk
),
CombinedSales AS (
    SELECT 
        sd.ws_ship_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        COALESCE(rd.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(rd.total_return_amount, 0) AS total_return_amount,
        (sd.total_sales - COALESCE(rd.total_return_amount, 0)) AS net_sales
    FROM SalesData sd
    LEFT JOIN ReturnData rd ON sd.ws_item_sk = rd.cr_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    /* Generates yearly purchase insights */
    ci.year,
    SUM(cs.total_sales) AS total_sales,
    SUM(cs.net_sales) AS net_sales,
    SUM(cs.total_return_quantity) AS total_return_quantity
FROM CustomerInfo ci 
LEFT JOIN CombinedSales cs ON ci.c_customer_sk = cs.ws_ship_date_sk
WHERE ci.rank <= 10 
GROUP BY ci.c_first_name, ci.c_last_name, ci.year
ORDER BY ci.year, total_sales DESC;
