
WITH RECURSIVE SalesCTE AS (
    SELECT ss_item_sk,
           ss_ticket_number,
           ss_quantity,
           ss_net_paid,
           1 AS hierarchy_level
    FROM store_sales
    WHERE ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    
    UNION ALL

    SELECT ss.item_sk,
           ss.ticket_number,
           ss.quantity,
           ss.net_paid,
           cte.hierarchy_level + 1
    FROM store_sales ss
    JOIN SalesCTE cte ON ss.ss_item_sk = cte.ss_item_sk
    WHERE cte.hierarchy_level < 5
), 

UniqueReturns AS (
    SELECT DISTINCT cr_item_sk,
           SUM(cr_return_quantity) AS total_returned
    FROM catalog_returns
    GROUP BY cr_item_sk
),

TopSellingItems AS (
    SELECT i_item_id,
           SUM(ss_quantity) AS total_sales,
           AVG(ss_net_paid_inc_tax) AS avg_net_paid
    FROM store_sales
    JOIN item ON store_sales.ss_item_sk = item.i_item_sk
    GROUP BY i_item_id
    HAVING SUM(ss_quantity) > 1000
    ORDER BY total_sales DESC
    LIMIT 10
)

SELECT tsi.i_item_id,
       tsi.total_sales,
       tsi.avg_net_paid,
       COALESCE(r.total_returned, 0) AS total_returns,
       (tsi.total_sales - COALESCE(r.total_returned, 0)) AS net_sales,
       ROW_NUMBER() OVER (ORDER BY tsi.total_sales DESC) AS sales_rank
FROM TopSellingItems tsi
LEFT JOIN UniqueReturns r ON tsi.i_item_id = r.cr_item_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = 
    (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer))
WHERE cd.cd_gender = 'F' 
    AND tsi.total_sales > (SELECT AVG(total_sales) FROM TopSellingItems)
    AND EXISTS (SELECT 1 FROM store WHERE s_closed_date_sk IS NULL)
ORDER BY net_sales DESC, sales_rank;
