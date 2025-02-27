
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales ws
)
SELECT 
    r.c_customer_id,
    r.c_first_name,
    r.c_last_name,
    r.cd_gender,
    s.ws_item_sk,
    SUM(s.ws_quantity) AS total_quantity_sold,
    SUM(s.ws_net_paid) AS total_sales,
    COALESCE(prom.p_discount_active, 'N') AS discount_status
FROM 
    RankedCustomers r
    LEFT JOIN SalesData s ON r.c_customer_id = s.ws_bill_customer_sk
    LEFT JOIN promotion prom ON s.ws_item_sk = prom.p_item_sk AND prom.p_start_date_sk <= CAST(CURRENT_DATE AS INTEGER) AND prom.p_end_date_sk >= CAST(CURRENT_DATE AS INTEGER)
WHERE 
    r.purchase_rank <= 10
GROUP BY 
    r.c_customer_id, 
    r.c_first_name, 
    r.c_last_name, 
    r.cd_gender, 
    s.ws_item_sk, 
    prom.p_discount_active
ORDER BY 
    total_sales DESC
FETCH FIRST 20 ROWS ONLY;
