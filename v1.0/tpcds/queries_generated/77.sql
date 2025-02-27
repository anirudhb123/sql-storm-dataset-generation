
WITH RankedReturns AS (
    SELECT 
        r.returning_customer_sk,
        r.return_quantity,
        r.returned_date_sk,
        ROW_NUMBER() OVER (PARTITION BY r.returning_customer_sk ORDER BY r.returned_date_sk DESC) AS rn
    FROM web_returns r
    WHERE r.returned_date_sk IS NOT NULL
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT ws_item_sk) AS distinct_items
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.hd_income_band_sk,
    COALESCE(ss.total_net_profit, 0) AS total_net_profit,
    COALESCE(ss.order_count, 0) AS order_count,
    COALESCE(ss.distinct_items, 0) AS distinct_items,
    COALESCE(rr.return_quantity, 0) AS recent_return_quantity
FROM CustomerInfo ci
LEFT JOIN SalesSummary ss ON ci.c_customer_sk = ss.customer_sk
LEFT JOIN (
    SELECT returning_customer_sk, return_quantity 
    FROM RankedReturns 
    WHERE rn = 1
) rr ON ci.c_customer_sk = rr.returning_customer_sk
WHERE 
    (ci.hd_income_band_sk IS NOT NULL OR ci.cd_gender = 'M')
    AND (ss.total_net_profit > 1000 OR rr.return_quantity > 5)
ORDER BY total_net_profit DESC, recent_return_quantity ASC
LIMIT 100;
