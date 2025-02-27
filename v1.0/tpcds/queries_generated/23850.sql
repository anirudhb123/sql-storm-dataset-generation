
WITH RecursiveSalesData AS (
    SELECT ss_store_sk, ss_item_sk, SUM(ss_sales_price) AS total_sales_price,
           COUNT(DISTINCT ss_ticket_number) AS total_transactions,
           RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ss_store_sk, ss_item_sk
),
TopStores AS (
    SELECT ss_store_sk, SUM(total_sales_price) AS top_store_sales
    FROM RecursiveSalesData
    WHERE sales_rank <= 10
    GROUP BY ss_store_sk
),
ItemInventory AS (
    SELECT inv.inv_item_sk, inv.inv_quantity_on_hand, 
           COALESCE(ws.ws_net_paid_inc_tax, 0) AS total_net_sales
    FROM inventory inv
    LEFT JOIN web_sales ws ON inv.inv_item_sk = ws.ws_item_sk
    WHERE inv.inv_quantity_on_hand > 0
),
ExtendedReturns AS (
    SELECT sr_item_sk, SUM(sr_return_amt_inc_tax) AS total_returned
    FROM store_returns
    GROUP BY sr_item_sk
),
SalesWithReturns AS (
    SELECT i.inv_item_sk, i.inv_quantity_on_hand, 
           COALESCE(s.total_sales_price, 0) AS total_sales, 
           COALESCE(r.total_returned, 0) AS total_returns,
           (COALESCE(s.total_sales_price, 0) - COALESCE(r.total_returned, 0)) AS net_revenue,
           COALESCE(i.inv_quantity_on_hand, 0) - COALESCE(r.total_returned, 0) AS available_inventory
    FROM ItemInventory i
    LEFT JOIN RecursiveSalesData s ON i.inv_item_sk = s.ss_item_sk
    LEFT JOIN ExtendedReturns r ON i.inv_item_sk = r.sr_item_sk
),
RevenueSummary AS (
    SELECT store.sk AS store_sk, SUM(s.net_revenue) AS total_net_revenue, 
           SUM(s.available_inventory) AS total_inventory_available,
           CASE 
             WHEN SUM(s.available_inventory) > 0 THEN SUM(s.total_sales) / NULLIF(SUM(s.available_inventory), 0)
             ELSE NULL 
           END AS avg_sales_per_item
    FROM TopStores ts
    JOIN store s ON ts.ss_store_sk = s.s_store_sk
    JOIN SalesWithReturns s ON s.inv_item_sk IN (SELECT DISTINCT cr_item_sk FROM catalog_returns)
    GROUP BY store.sk
)
SELECT *, 
       CASE 
         WHEN total_net_revenue > 10000 THEN 'High Performer'
         WHEN total_net_revenue BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
         ELSE 'Low Performer' 
       END AS performance_category
FROM RevenueSummary
WHERE total_inventory_available IS NOT NULL
ORDER BY total_net_revenue DESC;
