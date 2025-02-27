
WITH RECURSIVE SalesData AS (
    SELECT ss_item_sk, SUM(ss_ext_sales_price) AS total_sales, COUNT(DISTINCT ss_ticket_number) AS purchase_count
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY ss_item_sk
),
TopSellingItems AS (
    SELECT sd.ss_item_sk, sd.total_sales, ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) as rank
    FROM SalesData sd
    WHERE sd.purchase_count > 10
),
ItemDetails AS (
    SELECT i.i_item_id, i.i_product_name, i.i_category, t.rank
    FROM item i
    JOIN TopSellingItems t ON i.i_item_sk = t.ss_item_sk
)
SELECT id.i_item_id,
       id.i_product_name,
       COALESCE(id.i_category, 'Unknown') AS category,
       COALESCE(t.discount_percentage, 0) AS discount_percentage,
       CASE 
           WHEN t.rank <= 10 THEN 'Top 10 Seller'
           ELSE 'Beyond Top 10'
       END AS sales_ranking,
       CASE 
           WHEN id.i_item_id IS NULL THEN 'No details found'
           ELSE 'Item details available'
       END AS item_status
FROM ItemDetails id
LEFT JOIN (
    SELECT p.p_item_sk, 
           (SUM(CASE WHEN p.p_discount_active = 'Y' THEN p.p_cost ELSE 0 END) / NULLIF(SUM(p.p_cost), 0)) * 100 AS discount_percentage
    FROM promotion p
    GROUP BY p.p_item_sk
) t ON id.i_item_id = t.p_item_sk
LEFT JOIN (
    SELECT cd_demo_sk, MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM customer_demographics
    WHERE cd_credit_rating IS NOT NULL
    GROUP BY cd_demo_sk
) cd ON id.i_item_id = CAST(cd.cd_demo_sk AS CHAR(16))
WHERE id.i_product_name LIKE '%Special%'
  AND EXISTS (SELECT 1 
              FROM web_sales ws 
              WHERE ws.ws_item_sk = id.i_item_id 
                AND ws.ws_net_profit > 0)
ORDER BY id.i_product_name ASC
FETCH FIRST 50 ROWS ONLY;
