
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2450618 AND 2450618 + 30
    GROUP BY ws_item_sk
),
LatestPromotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        MAX(cd.demo_sk) AS latest_demo_sk
    FROM promotion p
    JOIN customer_demographics cd ON p.p_response_target = cd.cd_demo_sk
    WHERE p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 2023)
    GROUP BY p.p_promo_sk, p.p_promo_name
),
CustomerReturnStats AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
ReturnAnalysis AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(DISTINCT cr_order_number) AS catalog_returns,
        SUM(cr_return_amount) AS total_catalog_return_amount
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
FinalAnalysis AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        COALESCE(cs.catalog_returns, 0) AS catalog_returns,
        COALESCE(cs.total_catalog_return_amount, 0) AS total_catalog_return_amount,
        COALESCE(cs.total_returns, 0) AS store_returns,
        COALESCE(cs.total_return_amount, 0) AS total_store_return_amount,
        COALESCE(rs.total_quantity, 0) AS total_quantity,
        COALESCE(rs.total_net_profit, 0) AS total_net_profit,
        lp.p_promo_name
    FROM customer c
    LEFT JOIN CustomerReturnStats cs ON c.c_customer_sk = cs.sr_customer_sk
    LEFT JOIN ReturnAnalysis ra ON c.c_customer_sk = ra.cr_returning_customer_sk
    LEFT JOIN RankedSales rs ON c.c_customer_sk = rs.ws_item_sk
    LEFT JOIN LatestPromotions lp ON cs.total_returns > 10 AND lp.latest_demo_sk IS NOT NULL
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND (ca.ca_city IS NOT NULL OR ca.ca_state IS NOT NULL)
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    fa.catalog_returns,
    fa.total_catalog_return_amount,
    fa.store_returns,
    fa.total_store_return_amount,
    fa.total_quantity,
    fa.total_net_profit,
    fa.p_promo_name
FROM FinalAnalysis fa
JOIN customer c ON fa.c_customer_sk = c.c_customer_sk
WHERE (fa.total_net_profit > 0 OR fa.store_returns > 5)
ORDER BY fa.total_net_profit DESC, fa.store_returns ASC;
