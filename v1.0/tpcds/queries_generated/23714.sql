
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_price
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
), FilteredSales AS (
    SELECT 
        fs.ws_item_sk,
        fs.ws_order_number,
        fs.ws_sales_price,
        sa.ca_state,
        (SELECT COUNT(*) 
         FROM customer 
         WHERE c_current_cdemo_sk = fs.ws_bill_cdemo_sk 
         AND c_birth_year IS NOT NULL) AS customer_count
    FROM RankedSales AS fs
    LEFT JOIN item AS i ON fs.ws_item_sk = i.i_item_sk
    LEFT JOIN customer AS c ON fs.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address AS sa ON c.c_current_addr_sk = sa.ca_address_sk
    WHERE fs.rank_price = 1
    AND sa.ca_state IS NOT NULL
), SalesSummary AS (
    SELECT 
        ca_state, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(*) AS number_of_transactions,
        COUNT(DISTINCT ws_order_number) AS unique_orders
    FROM FilteredSales
    GROUP BY ca_state
), FinalOutput AS (
    SELECT 
        coalesce(SUM(total_sales), 0) AS overall_sales,
        AVG(number_of_transactions) AS avg_transactions_per_state,
        MAX(unique_orders) AS max_orders_in_any_state
    FROM SalesSummary
)
SELECT 
    fo.overall_sales,
    fo.avg_transactions_per_state,
    fo.max_orders_in_any_state,
    CASE 
        WHEN fo.avg_transactions_per_state > 100 THEN 'High Activity'
        WHEN fo.avg_transactions_per_state BETWEEN 50 AND 100 THEN 'Moderate Activity'
        ELSE 'Low Activity' 
    END AS activity_level
FROM FinalOutput AS fo
WHERE EXISTS (
    SELECT 1 
    FROM date_dim dd
    WHERE dd.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
    AND dd.d_current_year = 'Y'
)
AND (SELECT COUNT(*) FROM store_sales) > (SELECT COUNT(*) FROM store_returns)
ORDER BY overall_sales DESC
LIMIT 15;
