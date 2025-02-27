
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL AND 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
CustomerInfo AS (
    SELECT 
        c_customer_sk, 
        SUBSTRING(c_email_address, 1, CHARINDEX('@', c_email_address) - 1) AS email_prefix,
        cd_gender, 
        cd_marital_status
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
AggregateData AS (
    SELECT 
        ci.c_customer_sk,
        ci.email_prefix,
        COUNT(DISTINCT rs.ws_item_sk) AS total_items_bought,
        SUM(rs.ws_net_profit) AS total_profit
    FROM 
        CustomerInfo ci
    LEFT OUTER JOIN 
        RankedSales rs ON ci.c_customer_sk = rs.ws_sold_date_sk
    GROUP BY 
        ci.c_customer_sk, ci.email_prefix
),
IncomeRanges AS (
    SELECT 
        ib_income_band_sk,
        CASE 
            WHEN ib_lower_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('$', ib_lower_bound, ' - $', COALESCE(ib_upper_bound, 'Infinity'))
        END AS income_range
    FROM 
        income_band
),
FinalReport AS (
    SELECT 
        ad.c_customer_sk,
        ad.email_prefix,
        ir.income_range,
        ad.total_items_bought,
        ad.total_profit,
        NTILE(4) OVER (ORDER BY ad.total_profit DESC) AS profit_decile
    FROM 
        AggregateData ad
    LEFT JOIN 
        household_demographics hd ON ad.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        IncomeRanges ir ON hd.hd_income_band_sk = ir.ib_income_band_sk
)
SELECT 
    fr.c_customer_sk,
    fr.email_prefix,
    COALESCE(fr.income_range, 'No Income Data') AS income_range,
    fr.total_items_bought,
    fr.total_profit,
    CASE 
        WHEN fr.total_profit > 1000 THEN 'High Roller'
        WHEN fr.total_profit BETWEEN 500 AND 1000 THEN 'Moderate'
        WHEN fr.total_profit BETWEEN 1 AND 500 THEN 'Low Roller'
        ELSE 'No Profit'
    END AS customer_category
FROM 
    FinalReport fr
WHERE 
    fr.total_items_bought IS NOT NULL AND 
    fr.profit_decile = 1
ORDER BY 
    fr.total_profit DESC, fr.email_prefix ASC
LIMIT 100;
