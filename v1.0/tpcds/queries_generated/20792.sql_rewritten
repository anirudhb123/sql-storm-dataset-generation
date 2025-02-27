WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_country = 'USA'
    
    UNION ALL
    
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country
    FROM customer_address ca
    JOIN AddressCTE cte ON ca.ca_state = cte.ca_state 
    WHERE ca.ca_city <> cte.ca_city
),
IncomeBandStats AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(DISTINCT hd.hd_demo_sk) AS demographic_count,
        AVG(hd.hd_dep_count) AS average_dependencies,
        MAX(hd.hd_vehicle_count) AS max_vehicle_count
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY ib.ib_income_band_sk
),
SalesDetection AS (
    SELECT 
        'web' AS sales_channel,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_item_sk
    UNION ALL
    SELECT 
        'store' AS sales_channel,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit
    FROM store_sales
    GROUP BY ss_item_sk
),
FinalMetrics AS (
    SELECT 
        sales_channel,
        sd.ws_item_sk,
        total_quantity,
        total_profit,
        ROW_NUMBER() OVER (PARTITION BY sales_channel ORDER BY total_profit DESC) AS channel_rank
    FROM SalesDetection sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
),
CustomerReturnStats AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_value
    FROM catalog_returns
    GROUP BY cr_item_sk
),
TotalSalesWithReturns AS (
    SELECT 
        fm.sales_channel,
        fm.ws_item_sk,
        fm.total_quantity,
        fm.total_profit,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_value, 0) AS total_return_value,
        (fm.total_profit - COALESCE(cr.total_return_value, 0)) AS net_profit_after_returns
    FROM FinalMetrics fm
    LEFT JOIN CustomerReturnStats cr ON fm.ws_item_sk = cr.cr_item_sk
)
SELECT 
    DISTINCT cte.ca_city, 
    cte.ca_state,
    SUM(ts.total_quantity) AS overall_quantity,
    AVG(ts.net_profit_after_returns) AS avg_profit_after_returns,
    ibs.demographic_count,
    ibs.average_dependencies,
    ibs.max_vehicle_count,
    CASE 
        WHEN AVG(ts.net_profit_after_returns) > 1000 THEN 'High Value'
        WHEN AVG(ts.net_profit_after_returns) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_category
FROM TotalSalesWithReturns ts
INNER JOIN AddressCTE cte ON cte.ca_state IN ('CA', 'TX') 
INNER JOIN IncomeBandStats ibs ON ibs.demographic_count > 10
GROUP BY cte.ca_city, cte.ca_state, ibs.demographic_count, ibs.average_dependencies, ibs.max_vehicle_count
HAVING SUM(ts.total_quantity) > 500
ORDER BY overall_quantity DESC, value_category;