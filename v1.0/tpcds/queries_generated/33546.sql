
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
AddressAnalytics AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase
    FROM customer_address
    LEFT JOIN customer ON ca_address_sk = c_current_addr_sk
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY ca_city, ca_state
),
AggregatedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_net_loss) AS avg_net_loss
    FROM store_returns
    GROUP BY sr_item_sk
),
FinalReport AS (
    SELECT 
        s.sales_item,
        s.total_quantity,
        s.total_sales,
        COALESCE(a.customer_count, 0) AS customer_count,
        COALESCE(a.avg_purchase, 0) AS avg_purchase,
        COALESCE(r.total_returns, 0) AS total_returns,
        r.total_return_amount,
        r.avg_net_loss,
        ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM SalesCTE s
    LEFT JOIN AddressAnalytics a ON s.ws_item_sk = a.customer_count
    LEFT JOIN AggregatedReturns r ON s.ws_item_sk = r.sr_item_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales > 10000 THEN 'High Sales'
        WHEN total_sales > 5000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM FinalReport
WHERE sales_rank <= 50
ORDER BY total_sales DESC;
