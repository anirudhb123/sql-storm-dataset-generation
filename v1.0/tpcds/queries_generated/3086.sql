
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns
    WHERE sr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cr.total_returns,
        cr.total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cr.total_return_amount DESC) AS ranking
    FROM CustomerReturns cr
    JOIN CustomerDemographics cd ON cr.sr_customer_sk = cd.c_customer_sk
)
SELECT 
    tc.sr_customer_sk,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_returns,
    tc.total_return_amount,
    COALESCE((SELECT AVG(t.total_return_amount) 
               FROM TopCustomers t 
               WHERE t.cd_gender = tc.cd_gender
               AND t.ranking <= 10), 0) AS average_top_10_return_amount,
    CASE 
        WHEN tc.total_return_amount IS NULL THEN 'No returns'
        ELSE 'Returns made'
    END AS return_status
FROM TopCustomers tc
WHERE tc.ranking <= 5
ORDER BY tc.cd_gender, tc.total_return_amount DESC;

WITH InventoryCheck AS (
    SELECT 
        i.i_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM inventory i
    GROUP BY i.i_item_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 90 FROM date_dim)
    GROUP BY ws.ws_item_sk
),
ProductReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned_quantity
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
)
SELECT 
    i.i_item_sk,
    COALESCE(s.total_sold_quantity, 0) AS total_sold_quantity,
    COALESCE(s.total_net_profit, 0) AS total_net_profit,
    COALESCE(p.total_returned_quantity, 0) AS total_returned_quantity,
    CASE 
        WHEN COALESCE(s.total_sold_quantity, 0) = 0 THEN 'No sales'
        ELSE 'Sales recorded'
    END AS sales_status
FROM InventoryCheck i
LEFT JOIN SalesSummary s ON i.i_item_sk = s.ws_item_sk
LEFT JOIN ProductReturns p ON i.i_item_sk = p.cr_item_sk
ORDER BY total_net_profit DESC;
