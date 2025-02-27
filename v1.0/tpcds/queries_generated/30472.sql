
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= 20220101 
    GROUP BY ws_item_sk
),
CustomerSales AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        sd.total_quantity,
        sd.total_sales,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY sd.total_sales DESC) AS sales_rank
    FROM SalesData sd
    JOIN web_sales ws ON sd.ws_item_sk = ws.ws_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    COALESCE(cs.total_quantity, 0) AS total_quantity,
    COALESCE(cs.total_sales, 0.00) AS total_sales,
    ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS overall_rank
FROM CustomerSales cs
LEFT JOIN customer_address ca ON cs.c_customer_id = ca.ca_address_id
WHERE cs.sales_rank <= 10
AND (cs.cd_gender IS NOT NULL OR cs.total_sales > 0)
UNION
SELECT 
    'Overall Average' AS c_customer_id,
    NULL AS cd_gender,
    AVG(total_quantity) AS total_quantity,
    AVG(total_sales) AS total_sales,
    NULL AS overall_rank
FROM CustomerSales
WHERE total_sales IS NOT NULL
GROUP BY cs.cd_gender
ORDER BY overall_rank;
