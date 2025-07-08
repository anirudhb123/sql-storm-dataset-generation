
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LEFT(c.c_email_address, 10) AS email_prefix,
        LENGTH(c.c_email_address) AS email_length,
        COUNT(DISTINCT sr.sr_item_sk) AS returns_count,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns_amt
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, 
        w.w_warehouse_name
),
SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    ws.w_warehouse_name,
    ws.total_inventory,
    ss.total_sales,
    ss.order_count,
    cs.email_length,
    cs.returns_count,
    cs.total_returns_amt
FROM CustomerStats cs
JOIN WarehouseStats ws ON MOD(cs.c_customer_sk, 10) = MOD(ws.w_warehouse_sk, 10)
LEFT JOIN SalesStats ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
ORDER BY cs.c_customer_sk;
