
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year IN (2021, 2022)
                                AND d.d_moy BETWEEN 1 AND 6)
),
HighValueSales AS (
    SELECT 
        r.ws_order_number,
        SUM(r.ws_net_paid) AS total_net_paid
    FROM 
        RankedSales r
    WHERE 
        r.rn = 1
    GROUP BY 
        r.ws_order_number
    HAVING 
        SUM(r.ws_net_paid) > 1000
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependent_count,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.dependent_count,
    COALESCE(hvs.total_net_paid, 0) AS total_net_spent
FROM 
    CustomerInfo ci
LEFT JOIN 
    HighValueSales hvs ON ci.c_customer_sk = hvs.ws_order_number
WHERE 
    (ci.cd_gender = 'F' AND ci.dependent_count > 2)
    OR (ci.cd_gender = 'M' AND ci.dependent_count BETWEEN 1 AND 3)
ORDER BY 
    total_net_spent DESC
FETCH FIRST 10 ROWS ONLY;

WITH InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(CASE WHEN inv.inv_quantity_on_hand > 0 THEN 1 ELSE 0 END) AS in_stock_count,
        COUNT(*) AS total_records
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
    HAVING 
        SUM(CASE WHEN inv.inv_quantity_on_hand < 0 THEN 1 ELSE 0 END) = 0
),
InvalidItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(ic.total_records, 0) AS stock_records
    FROM 
        item i
    LEFT JOIN 
        InventoryCheck ic ON i.i_item_sk = ic.inv_item_sk
    WHERE 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
        AND (i.i_current_price IS NOT NULL AND i.i_current_price < 50.00)
)
SELECT 
    ii.i_item_sk,
    ii.i_item_desc,
    ii.i_current_price,
    CASE 
        WHEN ii.stock_records = 0 THEN 'Out of Stock'
        ELSE 'Available'
    END AS stock_status
FROM 
    InvalidItems ii
WHERE 
    ii.stock_records < 5 
ORDER BY 
    ii.i_current_price DESC;
