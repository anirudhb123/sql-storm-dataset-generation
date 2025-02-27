
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_cust_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_cust_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    JOIN customer ON ws_bill_customer_sk = c_customer_sk
    GROUP BY ws_cust_sk
),
RankedSales AS (
    SELECT 
        *,
        CASE 
            WHEN total_profit > 10000 THEN 'High'
            WHEN total_profit BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_band
    FROM SalesCTE
),
Promotions AS (
    SELECT 
        p.promo_id,
        COUNT(wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM web_returns wr
    JOIN promotion p ON wr_wr_reason_sk = p.p_promo_sk
    WHERE wr_return_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY p.promo_id
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    r.promo_id,
    r.total_returns,
    r.total_return_amount,
    rs.total_profit,
    rs.profit_band
FROM customer_address ca
LEFT JOIN RankedSales rs ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_current_cdemo_sk = rs.ws_cust_sk LIMIT 1)
LEFT JOIN Promotions r ON (rs.rank <= 10 AND r.promo_id IS NOT NULL)
WHERE ca.ca_city IS NOT NULL
AND (r.total_returns > 5 OR r.total_return_amount > 1000)
OR (rs.profit_band = 'High' AND rs.total_profit IS NOT NULL)
ORDER BY rs.total_profit DESC, ca.ca_city ASC NULLS LAST;
