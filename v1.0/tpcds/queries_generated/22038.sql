
WITH RankedReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS distinct_returns,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COALESCE(ib.ib_lower_bound, -1) + COALESCE(ib.ib_upper_bound, 0) AS income_band_adjusted
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales_orders
    FROM
        web_sales ws
    WHERE
        ws.ws_net_profit < (SELECT AVG(ws_net_profit) FROM web_sales)
    GROUP BY 
        ws.ws_item_sk
),
FinalReport AS (
    SELECT
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        COALESCE(s.total_net_profit, 0) AS sales_profit,
        COALESCE(r.total_returned, 0) AS total_item_returned,
        COALESCE(r.distinct_returns, 0) AS return_order_count,
        CASE 
            WHEN r.rn IS NOT NULL THEN 'Has Returns'
            ELSE 'No Returns'
        END AS return_status,
        CASE 
            WHEN cd.income_band_adjusted IS NULL THEN 'Unknown'
            WHEN cd.income_band_adjusted < 0 THEN 'Negative'
            ELSE 'Regular'
        END AS income_band_analysis
    FROM
        CustomerDetails cd
    LEFT JOIN
        (SELECT 
            sr_item_sk,
            MAX(rn) AS rn
        FROM
            RankedReturns 
        WHERE 
            rn < 5
        GROUP BY 
            sr_item_sk) r ON cd.c_customer_sk = r.sr_item_sk
    LEFT JOIN
        SalesSummary s ON cd.c_customer_sk = s.ws_item_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.sales_profit,
    f.total_item_returned,
    f.return_order_count,
    f.return_status,
    f.income_band_analysis
FROM
    FinalReport f
WHERE 
    f.return_status = 'Has Returns'
ORDER BY 
    f.sales_profit DESC, 
    f.return_order_count ASC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
