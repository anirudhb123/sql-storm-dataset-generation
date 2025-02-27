
WITH RECURSIVE SalesCTE AS (
    SELECT ss_item_sk, 
           SUM(ss_quantity) AS total_quantity, 
           SUM(ss_net_paid) AS total_net_paid,
           ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk DESC) AS rn
    FROM store_sales
    GROUP BY ss_item_sk
),
CustomerStats AS (
    SELECT c.c_customer_id,
           cd.cd_gender,
           cd.cd_marital_status,
           SUM(ws.ws_quantity) AS total_web_sales,
           MAX(ws.ws_net_profit) AS max_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
TopItemSales AS (
    SELECT ss_item_sk,
           SUM(ss_quantity) AS quantity_sold,
           SUM(ss_net_paid) AS sales_revenue
    FROM store_sales
    GROUP BY ss_item_sk
    HAVING SUM(ss_quantity) > 100
),
ItemRank AS (
    SELECT i.i_item_id,
           i.i_product_name,
           ts.quantity_sold,
           RANK() OVER (ORDER BY ts.quantity_sold DESC) AS item_rank
    FROM item i
    JOIN TopItemSales ts ON i.i_item_sk = ts.ss_item_sk
)
SELECT cs.c_customer_id,
       cs.total_web_sales,
       cs.max_net_profit,
       ir.i_product_name,
       ir.quantity_sold,
       CASE WHEN cs.total_web_sales IS NULL THEN 'No Sales' ELSE 'Sales Exists' END AS sales_status
FROM CustomerStats cs
FULL OUTER JOIN ItemRank ir ON cs.c_customer_id = ir.i_item_id
WHERE (ir.quantity_sold > 500 OR ir.quantity_sold IS NULL)
ORDER BY cs.total_web_sales DESC NULLS LAST, ir.quantity_sold DESC;
