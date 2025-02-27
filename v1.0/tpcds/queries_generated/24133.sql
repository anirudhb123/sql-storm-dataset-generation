
WITH RECURSIVE InventoryCTE AS (
    SELECT 
        inv_date_sk, 
        inv_item_sk, 
        inv_warehouse_sk, 
        inv_quantity_on_hand,
        ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk DESC) as rn
    FROM inventory
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
SalesReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(sr_return_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(*) AS demographic_count
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    coalesce(cs.total_quantity, 0) AS total_sales_quantity,
    coalesce(sr.total_returns, 0) AS total_returns_quantity,
    cd.avg_purchase_estimate,
    cd.demographic_count,
    CASE 
        WHEN coalesce(cs.total_quantity, 0) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status,
    (SELECT COUNT(*) FROM inventory WHERE inv_quantity_on_hand = 0) AS out_of_stock_count,
    (SELECT MAX(i.i_current_price) FROM item i WHERE i.i_item_sk IN (SELECT inv_item_sk FROM inventory)) AS highest_priced_item,
    ROW_NUMBER() OVER (ORDER BY c.c_last_name) AS customer_rank
FROM customer c
LEFT JOIN CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN SalesReturns sr ON c.c_customer_sk = sr.sr_returning_customer_sk
JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M') 
AND (EXISTS (SELECT 1 FROM InventoryCTE i WHERE i.inv_quantity_on_hand < 5 AND i.inv_item_sk = cs.total_quantity) 
OR cs.total_orders IS NULL)
ORDER BY customer_rank
