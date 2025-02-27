
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_returned_date_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rnk
    FROM store_returns
    GROUP BY sr_returned_date_sk
),
CustomerAddressInfo AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_gmt_offset
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ProcessedWebSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
MaxProfitItem AS (
    SELECT 
        pwi.ws_item_sk,
        pwi.total_net_profit,
        DENSE_RANK() OVER (ORDER BY pwi.total_net_profit DESC) AS profit_rank
    FROM ProcessedWebSales pwi
    WHERE pwi.total_quantity_sold > (SELECT AVG(total_quantity_sold) FROM ProcessedWebSales) 
    AND pwi.total_net_profit IS NOT NULL
),
FinalReport AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        COALESCE(SUM(r.return_count), 0) AS total_returns,
        COALESCE(SUM(w.total_net_profit), 0) AS total_net_profit,
        SUM(CASE WHEN w.total_net_profit > 0 THEN 1 ELSE 0 END) AS profitable_sales
    FROM CustomerAddressInfo ca
    LEFT JOIN RankedReturns r ON r.sr_returned_date_sk = (SELECT MAX(sr_returned_date_sk) FROM store_returns)
    LEFT JOIN ProcessedWebSales w ON w.ws_item_sk IN (SELECT ws_item_sk FROM MaxProfitItem WHERE profit_rank = 1)
    GROUP BY ca.ca_city, ca.ca_state
)
SELECT 
    f.ca_city,
    f.ca_state,
    f.customer_count,
    f.total_returns,
    f.total_net_profit,
    f.profitable_sales,
    CASE 
        WHEN f.total_net_profit > 10000 THEN 'High Profit'
        WHEN f.total_net_profit BETWEEN 5000 AND 10000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM FinalReport f
WHERE f.customer_count > 10
ORDER BY f.total_net_profit DESC, f.ca_state ASC;
