
WITH RECURSIVE sales_combined AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_web_sales,
        SUM(cs.cs_quantity) AS total_catalog_sales,
        SUM(ss.ss_quantity) AS total_store_sales,
        COALESCE(NULLIF(SUM(ws.ws_quantity), 0), NULLIF(SUM(cs.cs_quantity), 0), NULLIF(SUM(ss.ss_quantity), 0)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank
    FROM
        web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    FULL OUTER JOIN store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    GROUP BY ws.ws_item_sk
),
filtered_sales AS (
    SELECT 
        item_sk,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        total_sales
    FROM 
        sales_combined
    WHERE 
        rank = 1 AND total_sales IS NOT NULL
    HAVING 
        (total_web_sales > 100 OR total_catalog_sales < 50)
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        cd.cd_gender,
        COALESCE(NULLIF(cd.cd_marital_status, 'S'), 'Unknown') AS marital_status,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year DESC) AS rank
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state = 'NY' AND ca.ca_country = 'USA'
)
SELECT 
    ci.c_customer_id,
    si.item_sk,
    fs.total_web_sales,
    fs.total_catalog_sales,
    fs.total_store_sales,
    (COALESCE(fs.total_web_sales, 0) 
     + COALESCE(fs.total_catalog_sales, 0) 
     + COALESCE(fs.total_store_sales, 0)) AS grand_total,
    CURRENT_TIMESTAMP AS run_time
FROM 
    filtered_sales fs
JOIN customer_info ci ON fs.item_sk = (SELECT MIN(item_sk) FROM filtered_sales)
WHERE 
    ci.rank = 1 
    AND ((fs.total_web_sales + fs.total_catalog_sales + fs.total_store_sales) % 5 = 0)
ORDER BY grand_total DESC
LIMIT 10;
