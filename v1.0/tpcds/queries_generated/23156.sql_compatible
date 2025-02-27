
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        COALESCE(NULLIF(ws.ws_net_paid, 0), ws.ws_net_paid_inc_tax) AS adjusted_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS sale_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (
            SELECT MIN(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023
        )
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        COALESCE(i.ib_income_band_sk, -1) AS income_band_sk
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN income_band i ON i.ib_lower_bound <= cd.cd_purchase_estimate
        AND (i.ib_upper_bound > cd.cd_purchase_estimate OR i.ib_upper_bound IS NULL)
),
InventoryStatus AS (
    SELECT 
        i.inv_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_on_hand,
        MAX(CASE WHEN wd.d_dow = 6 THEN i.inv_quantity_on_hand END) AS saturday_stock,
        MIN(CASE WHEN wd.d_dow = 1 THEN i.inv_quantity_on_hand END) AS monday_stock
    FROM 
        inventory i
    JOIN date_dim wd ON wd.d_date_sk = i.inv_date_sk
    WHERE 
        wd.d_year >= 2023
    GROUP BY 
        i.inv_item_sk
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    MAX(sd.adjusted_net_paid) AS max_paid,
    SUM(CASE WHEN sd.sale_rank = 1 THEN sd.ws_sales_price ELSE 0 END) AS first_sale_price,
    COUNT(DISTINCT sd.ws_item_sk) AS total_unique_items_purchased,
    COALESCE(ISNULL(is.total_on_hand, 0), 0) AS total_inventory,
    COALESCE(is.saturday_stock, 0) AS stock_on_saturday,
    NULLIF(MAX(is.monday_stock), 0) AS monday_inventory
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData sd ON sd.ws_item_sk = ci.c_current_hdemo_sk
LEFT JOIN 
    InventoryStatus is ON is.inv_item_sk = sd.ws_item_sk
WHERE 
    ci.cd_gender = 'M'
    AND (ci.cd_marital_status IS NULL OR ci.cd_dep_count > 0)
GROUP BY 
    ci.c_customer_sk, ci.cd_gender
HAVING 
    SUM(sd.ws_sales_price) > 100
ORDER BY 
    max_paid DESC, total_unique_items_purchased ASC
LIMIT 100 OFFSET 0;
