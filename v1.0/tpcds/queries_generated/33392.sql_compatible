
WITH RECURSIVE customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_sales_price), 0) AS total_catalog_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(ws.ws_sales_price), 0) DESC) AS rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        (cs.total_web_sales + cs.total_catalog_sales) AS total_sales
    FROM customer_sales cs
    WHERE cs.rank = 1 
    AND (cs.total_web_sales > 1000 OR cs.total_catalog_sales > 500)
),
inventory_summary AS (
    SELECT 
        i.i_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity
    FROM inventory i
    GROUP BY i.i_item_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    ii.i_item_sk,
    COALESCE(ii.total_quantity, 0) AS available_inventory,
    CASE 
        WHEN hvc.total_sales > 1500 THEN 'High Value'
        ELSE 'Regular Customer'
    END AS customer_category
FROM high_value_customers hvc
LEFT JOIN inventory_summary ii ON ii.i_item_sk IN (
    SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_ship_customer_sk = hvc.c_customer_sk
    UNION 
    SELECT cs.cs_item_sk FROM catalog_sales cs WHERE cs.cs_ship_customer_sk = hvc.c_customer_sk
)
ORDER BY hvc.c_first_name, hvc.c_last_name;
