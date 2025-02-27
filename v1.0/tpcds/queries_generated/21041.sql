
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rank_profit
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6
    )
    GROUP BY cs_item_sk
), CustomerSegmentation AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            WHEN cd_purchase_estimate < 100 THEN 'LOW'
            WHEN cd_purchase_estimate BETWEEN 100 AND 500 THEN 'MEDIUM'
            ELSE 'HIGH'
        END AS purchase_segment,
        COUNT(DISTINCT c.c_email_address) AS unique_visitors
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL OR c.c_birth_month IS NOT NULL
    GROUP BY c.c_customer_sk, cd_purchase_estimate
), TotalReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns 
    FROM store_returns 
    GROUP BY sr_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(rs.total_quantity, 0) AS total_quantity_sold,
    COALESCE(rs.total_net_profit, 0) AS total_net_profit,
    COALESCE(tr.total_returns, 0) AS total_returns,
    cs.purchase_segment,
    CONCAT('Total Quantity:', COALESCE(rs.total_quantity, 0), 
           ' | Net Profit:', COALESCE(rs.total_net_profit, 0),
           ' | Returns:', COALESCE(tr.total_returns, 0)) AS sales_summary
FROM item i
LEFT JOIN RankedSales rs ON i.i_item_sk = rs.cs_item_sk
LEFT JOIN TotalReturns tr ON i.i_item_sk = tr.sr_item_sk
LEFT JOIN CustomerSegmentation cs ON cs.c_customer_sk IN (
    SELECT DISTINCT ws_bill_customer_sk 
    FROM web_sales 
    WHERE ws_sold_date_sk > 0
)
WHERE 
    (rs.rank_profit <= 5 OR rs.rank_profit IS NULL)
    AND (i.i_current_price > 20 OR i.i_item_desc LIKE '%Gadget%')
ORDER BY total_net_profit DESC NULLS LAST;
