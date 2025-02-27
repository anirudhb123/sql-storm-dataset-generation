
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        NULL AS parent_customer_sk,
        1 AS level
    FROM customer
    WHERE c_customer_id = 'CUST001'
    
    UNION ALL
    
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        sh.c_customer_sk AS parent_customer_sk,
        sh.level + 1
    FROM customer AS cs
    JOIN store_sales AS ss ON cs.ss_customer_sk = ss.ss_customer_sk
    JOIN SalesHierarchy AS sh ON ss.ss_customer_sk = sh.c_customer_sk
)

SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS gender_rank,
    COUNT(DISTINCT ws.ws_order_number) OVER () AS total_orders
FROM 
    SalesHierarchy sh
LEFT JOIN customer_demographics cd ON sh.c_customer_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON sh.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    cd.cd_gender, cd.cd_marital_status
HAVING 
    total_spent > 1000
ORDER BY 
    total_spent DESC;

WITH TopItems AS (
    SELECT 
        i_item_id,
        SUM(ws.ws_quantity) AS total_sold
    FROM 
        item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i_item_id
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(t.total_sold, 0) AS total_sold
FROM 
    item i
LEFT JOIN TopItems t ON i.i_item_id = t.i_item_id
WHERE 
    i.i_current_price > (
        SELECT AVG(i2.i_current_price)
        FROM item i2
        WHERE i2.i_rec_start_date < CURRENT_DATE
    )
ORDER BY 
    total_sold DESC, i.i_item_id
FETCH FIRST 10 ROWS ONLY;

SELECT 
    DISTINCT ca.ca_state,
    COUNT(c.c_customer_sk) AS customer_count,
    SUM(ws.ws_sales_price) AS total_sales
FROM 
    customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ca.ca_state
HAVING 
    COUNT(c.c_customer_sk) > 5
ORDER BY 
    total_sales DESC;

SELECT 
    DISTINCT ib.ib_income_band_sk,
    COUNT(cd.cd_demo_sk) AS demographic_count,
    AVL.GREAT_GIG_ID AS greatest_performance
FROM 
    income_band ib
LEFT JOIN household_demographics hd ON ib.ib_income_band_sk = hd.hd_income_band_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = hd.hd_demo_sk
JOIN (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS GREAT_GIG_ID
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
) AVL ON true
GROUP BY 
    ib.ib_income_band_sk
HAVING 
    demographic_count > 10
ORDER BY 
    demographic_count DESC;
