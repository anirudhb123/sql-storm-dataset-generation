
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_by_sales
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2020)
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
), 
DemoStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN hd.hd_income_band_sk IS NULL THEN 1 ELSE 0 END) AS no_income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        (cd.cd_marital_status IS NULL OR cd.cd_marital_status = 'S') 
        AND cd.cd_credit_rating <> 'Bad' 
        AND c.c_birth_year BETWEEN 1960 AND 2000
    GROUP BY 
        cd.cd_gender
), 
InventoryStatus AS (
    SELECT 
        inv.inv_item_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    i.i_item_id, 
    i.i_item_desc, 
    COALESCE(rs.total_quantity, 0) AS web_sales_quantity,
    COALESCE(is.total_quantity_on_hand, 0) AS inventory_quantity,
    ds.customer_count AS demographics_customer_count,
    ds.no_income_band AS demographics_no_income_band
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.rank_by_sales = 1
LEFT JOIN 
    InventoryStatus is ON i.i_item_sk = is.inv_item_sk
LEFT JOIN 
    DemoStats ds ON ds.cd_gender = CASE 
        WHEN CHAR_LENGTH(i.i_item_id) % 2 = 0 THEN 'M' 
        ELSE 'F' 
    END
WHERE 
    (i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2 
                          WHERE i2.i_rec_start_date < CURRENT_DATE 
                          AND i2.i_rec_end_date IS NULL)
     OR i.i_current_price IS NULL)
    AND i.i_size NOT IN ('Large', 'Extra Large')
ORDER BY 
    web_sales_quantity DESC, 
    inventory_quantity ASC NULLS LAST
LIMIT 100
```
