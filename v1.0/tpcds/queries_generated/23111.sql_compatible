
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
),
HighProfitSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM RankedSales rs
    WHERE rs.rank <= 5
    GROUP BY rs.ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating,
        ci.total_quantity,
        ci.total_net_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN HighProfitSales ci ON ci.ws_item_sk IN (
        SELECT DISTINCT ws_item_sk 
        FROM web_sales 
        WHERE ws_bill_customer_sk = c.c_customer_sk
    )
),
StoreSalesSummary AS (
    SELECT 
        ss_store_sk,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        AVG(ss_net_profit) AS avg_net_profit
    FROM store_sales
    WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_dow = 6 AND d_year = 2023)
    GROUP BY ss_store_sk
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.credit_rating,
    COALESCE(s.total_transactions, 0) AS total_transactions,
    COALESCE(s.avg_net_profit, 0.00) AS avg_net_profit,
    COALESCE(ci.total_quantity, 0) AS total_quantity,
    COALESCE(ci.total_net_profit, 0.00) AS total_net_profit
FROM CustomerInfo ci
FULL OUTER JOIN StoreSalesSummary s ON ci.c_customer_sk IS NOT NULL OR s.ss_store_sk IS NOT NULL
WHERE (ci.cd_marital_status = 'M' OR ci.cd_marital_status IS NULL) 
AND (ci.total_net_profit > (SELECT AVG(total_net_profit) FROM HighProfitSales) OR ci.total_quantity IS NULL)
ORDER BY ci.c_customer_sk;
