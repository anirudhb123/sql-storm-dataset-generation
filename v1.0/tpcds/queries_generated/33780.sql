
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_marital_status, cd.cd_gender, cd.cd_purchase_estimate,
           CAST(1 AS INTEGER) AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M' AND cd.cd_marital_status = 'S'
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_marital_status, cd.cd_gender, cd.cd_purchase_estimate,
           h.level + 1
    FROM customer c
    JOIN CustomerHierarchy h ON c.c_current_cdemo_sk = h.c_current_cdemo_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND h.level < 3
),
ItemSales AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_sold
    FROM web_sales ws
    INNER JOIN CustomerHierarchy ch ON ws.ws_bill_cdemo_sk = ch.c_current_cdemo_sk
    GROUP BY ws.ws_item_sk
    HAVING SUM(ws.ws_quantity) > 100
),
SalesDetails AS (
    SELECT i.i_item_sk, i.i_product_name, i.i_current_price, is.total_sold,
           RANK() OVER (PARTITION BY i.i_category_id ORDER BY is.total_sold DESC) AS rank
    FROM item i
    LEFT JOIN ItemSales is ON i.i_item_sk = is.ws_item_sk
),
FinalSales AS (
    SELECT fd.i_product_name, fd.i_current_price, fd.total_sold, 
           COALESCE(rv.r_reason_desc, 'No Reason') AS return_reason,
           CASE 
               WHEN fd.total_sold IS NULL THEN 'No Sales'
               ELSE 'Sales Recorded'
           END AS sales_status
    FROM SalesDetails fd
    LEFT JOIN reason rv ON fd.total_sold < 0
)
SELECT fs.i_product_name, fs.i_current_price, fs.total_sold, fs.return_reason, fs.sales_status
FROM FinalSales fs
WHERE fs.rank <= 5
ORDER BY fs.total_sold DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
