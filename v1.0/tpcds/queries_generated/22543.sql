
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_returned_date_sk,
        SR_item_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rn,
        SUM(sr_return_quantity) OVER (PARTITION BY sr_customer_sk) AS total_returned_quantity
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
),
AggregatedSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_profit) AS avg_net_profit,
        COUNT(*) FILTER (WHERE ws_ship_mode_sk IS NOT NULL) AS shipped_orders
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'U') AS gender,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    COALESCE(ar.total_sales, 0) AS total_sales,
    COALESCE(ar.order_count, 0) AS order_count,
    COALESCE(rr.total_returned_quantity, 0) AS total_returned_quantity,
    cd.gender,
    cd.avg_purchase_estimate,
    CASE 
        WHEN rr.rn IS NULL THEN 'No Returns'
        WHEN rr.total_returned_quantity > 0 THEN 'High Returner'
        ELSE 'Normal'
    END AS customer_return_status
FROM CustomerDetails cd
LEFT JOIN AggregatedSales ar ON cd.c_customer_sk = ar.customer_sk
LEFT JOIN RankedReturns rr ON cd.c_customer_sk = rr.sr_customer_sk AND rr.rn = 1
WHERE cd.avg_purchase_estimate > COALESCE((SELECT MAX(cd2.cd_purchase_estimate) 
                                            FROM customer_demographics cd2 
                                            WHERE cd2.cd_gender = cd.gender), 0)
ORDER BY total_sales DESC, cd.c_last_name ASC;
