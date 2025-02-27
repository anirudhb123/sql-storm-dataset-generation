
WITH RankedReturns AS (
    SELECT 
        cr_returning_customer_sk,
        cr_item_sk,
        cr_return_quantity,
        cr_return_amount,
        ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY cr_returned_date_sk DESC) AS rn
    FROM catalog_returns
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid) AS average_paid
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_item_sk
),
FinalReport AS (
    SELECT 
        cd.c_customer_id,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        sd.average_paid,
        COALESCE(rr.cr_return_quantity, 0) AS return_quantity,
        COALESCE(rr.cr_return_amount, 0) AS return_amount
    FROM CustomerDetails cd
    JOIN SalesData sd ON EXISTS (
        SELECT 1 FROM RankedReturns rr WHERE rr.cr_returning_customer_sk = cd.c_customer_id AND rr.rn = 1
    )
    LEFT JOIN RankedReturns rr ON rr.cr_returning_customer_sk = cd.c_customer_id
)
SELECT 
    fr.c_customer_id,
    fr.ws_item_sk,
    fr.total_quantity,
    fr.total_profit,
    fr.average_paid,
    CASE 
        WHEN fr.return_quantity < 0 THEN NULL
        WHEN fr.return_quantity > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status,
    CASE 
        WHEN fr.average_paid IS NULL THEN 'No sales data'
        WHEN fr.average_paid > 100 THEN 'Premium Customer'
        ELSE 'Standard Customer'
    END AS customer_category
FROM FinalReport fr
WHERE fr.total_profit > 1000
ORDER BY fr.total_quantity DESC, fr.average_paid ASC;
