
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_return_ticket_number) AS total_returns,
        SUM(CASE 
                WHEN sr_return_quantity IS NOT NULL THEN sr_return_quantity 
                ELSE 0 
            END) AS total_returned_quantity
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_id
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate < 10000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'High' 
        END AS purchase_power
    FROM customer_demographics cd
),
FinalReport AS (
    SELECT 
        cr.c_customer_id,
        id.total_sales,
        id.total_orders,
        cd.purchase_power,
        cr.total_returns,
        cr.total_returned_quantity,
        COALESCE(id.total_sales, 0) - COALESCE(cr.total_returned_quantity, 0) AS net_sales
    FROM CustomerReturnStats cr
    JOIN ItemSales id ON id.ws_item_sk = (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = 
        (SELECT c_customer_sk FROM customer WHERE c_customer_id = cr.c_customer_id) LIMIT 1)
    JOIN CustomerDemographics cd ON cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_id = cr.c_customer_id)
    WHERE cr.total_returns > 0 OR cd.cd_marital_status = 'M'
)
SELECT 
    f.c_customer_id,
    f.total_sales,
    f.total_orders,
    f.purchase_power,
    f.total_returns,
    f.total_returned_quantity,
    f.net_sales,
    ROW_NUMBER() OVER (PARTITION BY f.purchase_power ORDER BY f.net_sales DESC) AS sales_rank
FROM FinalReport f
WHERE f.total_sales > 500
ORDER BY f.purchase_power, f.net_sales DESC;
