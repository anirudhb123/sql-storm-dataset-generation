
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
    UNION ALL
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_sales_price DESC) AS rn
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
)
, DistinctSales AS (
    SELECT 
        DISTINCT rs.ws_order_number, 
        rs.ws_item_sk,
        rs.ws_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.rn = 1 OR rs.ws_sales_price IS NULL
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_spent,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.total_spent,
    ci.catalog_orders,
    ds.ws_item_sk,
    SUM(ds.ws_sales_price) AS total_item_sales
FROM 
    CustomerInfo ci
LEFT JOIN DistinctSales ds ON ci.c_customer_id = ds.ws_order_number::varchar
WHERE 
    ci.total_spent > (
        SELECT AVG(total_spent) FROM CustomerInfo WHERE cd_marital_status = 'S'
    ) 
OR 
    (ci.cd_gender IS NULL AND ci.catalog_orders > (
        SELECT COUNT(*) FROM catalog_sales WHERE cs_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type LIKE 'Air%')
    ))
GROUP BY 
    ci.c_customer_id, ci.cd_gender, ci.cd_marital_status, ds.ws_item_sk
HAVING 
    COUNT(ds.ws_item_sk) > 0
ORDER BY 
    total_item_sales DESC, ci.total_spent DESC;
