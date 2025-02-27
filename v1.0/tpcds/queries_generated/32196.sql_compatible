
WITH RECURSIVE income_distribution AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound, 1 AS level
    FROM income_band
    WHERE ib_lower_bound <= (SELECT AVG(CASE WHEN cd_demo_sk IS NOT NULL THEN cd_purchase_estimate END) FROM customer_demographics)
    
    UNION ALL
    
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, id.level + 1
    FROM income_band ib
    JOIN income_distribution id ON ib.ib_lower_bound > id.ib_upper_bound
    WHERE id.level < 4
), 
sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
), 
return_data AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(sd.total_quantity, 0) AS total_quantity_sold,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_return_amt, 0) AS total_return_amt,
    (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return_amt, 0)) AS net_sales,
    CASE 
        WHEN (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return_amt, 0)) > 0 THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status,
    id.ib_income_band_sk
FROM item i
LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN return_data rd ON i.i_item_sk = rd.wr_item_sk
CROSS JOIN income_distribution id
WHERE id.ib_lower_bound <= (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
AND (sd.total_quantity IS NOT NULL OR rd.total_returns IS NOT NULL)
ORDER BY net_sales DESC, total_quantity_sold DESC
LIMIT 100;
