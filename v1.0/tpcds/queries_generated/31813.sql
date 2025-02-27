
WITH RECURSIVE SalesCTE AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_paid) AS total_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2451920 AND 2452050
    GROUP BY ws_item_sk
    UNION ALL
    SELECT cs_item_sk, SUM(cs_quantity) + s.total_quantity, SUM(cs_net_paid) + s.total_net_paid
    FROM catalog_sales cs
    JOIN SalesCTE s ON cs.cs_item_sk = s.ws_item_sk
    WHERE cs_sold_date_sk BETWEEN 2451920 AND 2452050
    GROUP BY cs_item_sk
),
RankedSales AS (
    SELECT item.i_item_id, item.i_product_name, s.total_quantity, s.total_net_paid,
           RANK() OVER (ORDER BY s.total_net_paid DESC) AS sales_rank
    FROM item
    JOIN SalesCTE s ON item.i_item_sk = s.ws_item_sk
)
SELECT r.item_id, r.product_name, r.total_quantity, r.total_net_paid,
       CASE
           WHEN r.total_net_paid IS NULL THEN 'No Sales'
           ELSE CAST(r.total_net_paid AS CHAR(20))
       END AS formatted_net_paid,
       COALESCE((SELECT SUM(sr_return_quantity)
                  FROM store_returns sr
                  WHERE sr_item_sk = r.item_id
                  AND sr_returned_date_sk BETWEEN 2451920 AND 2452050), 0) AS total_returns
FROM RankedSales r
LEFT OUTER JOIN customer_demographics cd ON r.sales_rank <= cd.cd_demo_sk
WHERE r.total_quantity > 100
ORDER BY r.sales_rank
FETCH FIRST 50 ROWS ONLY;
