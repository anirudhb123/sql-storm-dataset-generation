
WITH RecursiveCustomerCTE AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
DateWarehouseCTE AS (
    SELECT d.d_date, w.w_warehouse_id, w.w_warehouse_name,
           COUNT(DISTINCT i.i_item_sk) AS total_items,
           SUM(CASE WHEN i.i_current_price IS NOT NULL THEN i.i_current_price ELSE 0 END) AS total_price
    FROM date_dim d
    JOIN inventory inv ON d.d_date_sk = inv.inv_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY d.d_date, w.w_warehouse_id, w.w_warehouse_name
),
RankedReturns AS (
    SELECT sr.returned_date_sk, COUNT(*) AS total_returns, SUM(sr.return_amt) AS total_return_amount,
           RANK() OVER (PARTITION BY sr.refunded_customer_sk ORDER BY SUM(sr.return_amt) DESC) AS return_rank
    FROM store_returns sr
    GROUP BY sr.returned_date_sk, sr.refunded_customer_sk
),
WebSalesAnalysis AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_sales_price) AS total_sales, COUNT(ws.ws_order_number) AS order_count,
           CASE 
               WHEN SUM(ws.ws_sales_price) > 10000 THEN 'High'
               WHEN SUM(ws.ws_sales_price) BETWEEN 1000 AND 10000 THEN 'Medium'
               ELSE 'Low'
           END AS sales_category
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_item_sk
)
SELECT cte.c_first_name, cte.c_last_name, cte.cd_gender, cte.cd_marital_status, cte.cd_purchase_estimate,
       dwc.w_warehouse_name, dwc.total_items, dwc.total_price, 
       rrt.total_returns, rrt.total_return_amount, rrt.return_rank,
       wsa.total_sales, wsa.order_count, wsa.sales_category
FROM RecursiveCustomerCTE cte
LEFT JOIN DateWarehouseCTE dwc ON dwc.total_items > 10
LEFT JOIN RankedReturns rrt ON rrt.refunded_customer_sk = cte.c_customer_sk
LEFT JOIN WebSalesAnalysis wsa ON wsa.ws_item_sk = (SELECT i.i_item_sk FROM item i WHERE i.i_brand = 'BrandX')
WHERE cte.rank <= 5 AND (cte.cd_marital_status IS NOT NULL OR cte.cd_demo_sk IS NOT NULL)
ORDER BY cte.cd_purchase_estimate DESC, dwc.total_price ASC
LIMIT 50;
