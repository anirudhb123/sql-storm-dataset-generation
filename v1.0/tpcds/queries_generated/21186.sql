
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS item_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_country = 'USA'
        AND ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    sd.ws_item_sk,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    COALESCE(sd.total_sales, 0) AS total_sales
FROM 
    RankedCustomers rc
LEFT JOIN 
    SalesData sd ON rc.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_first_shipto_date_sk IS NOT NULL LIMIT 1)
WHERE 
    rc.rank <= 10
ORDER BY 
    rc.cd_gender, total_sales DESC
LIMIT 100
UNION ALL
SELECT 
    '-Total-' AS c_customer_id,
    NULL AS cd_gender,
    NULL AS ws_item_sk,
    SUM(COALESCE(sd.total_quantity, 0)) AS total_quantity,
    SUM(COALESCE(sd.total_sales, 0)) AS total_sales
FROM 
    SalesData sd
WHERE 
    sd.item_rank <= 5;
