
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate,
        COALESCE(d.d_year, 2023) AS customer_since,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
TopCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_income_band_sk,
        ci.cd_purchase_estimate
    FROM CustomerInfo ci
    WHERE ci.rnk <= 10
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    JOIN TopCustomers tc ON ws.ws_bill_customer_sk = tc.c_customer_sk
    GROUP BY ws.ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    sd.total_quantity,
    sd.total_net_paid,
    sd.total_discount,
    CASE 
        WHEN sd.total_net_paid > 10000 THEN 'High Value'
        WHEN sd.total_net_paid BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_value_category,
    ROW_NUMBER() OVER (ORDER BY sd.total_net_paid DESC) AS rank
FROM inventory inv
JOIN SalesData sd ON inv.inv_item_sk = sd.ws_item_sk
JOIN item i ON inv.inv_item_sk = i.i_item_sk
WHERE inv.inv_quantity_on_hand > 0
  AND sd.total_quantity IS NOT NULL
  AND (i.i_category = 'Electronics' OR i.i_category = 'Apparel')
ORDER BY sd.total_net_paid DESC
LIMIT 50;
