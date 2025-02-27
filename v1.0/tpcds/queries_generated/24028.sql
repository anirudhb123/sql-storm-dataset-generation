
WITH RecursiveCustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_quantity) DESC) AS rank
    FROM web_returns
    GROUP BY wr_returning_customer_sk, wr_item_sk
),
HighValueItems AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_current_price,
        CASE 
            WHEN i_current_price > 100 THEN 'High'
            WHEN i_current_price BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low' 
        END AS price_category
    FROM item
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            ELSE CAST(cd.cd_purchase_estimate AS VARCHAR)
        END AS purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnSummary AS (
    SELECT 
        cc.c_customer_sk,
        COUNT(DISTINCT r.wr_item_sk) AS unique_items_returned,
        SUM(r.wr_return_quantity) AS total_returned_quantity,
        MAX(r.wr_returned_amnt) AS max_return_amount,
        AVG(COALESCE(NULLIF(r.wr_return_amt_inc_tax, 0), NULL)) AS avg_return_amt
    FROM web_returns r
    LEFT JOIN CustomerDetails cc ON r.wr_returning_customer_sk = cc.c_customer_sk
    WHERE r.wr_reason_sk IS NOT NULL
    GROUP BY cc.c_customer_sk
),
FinalMetrics AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(rs.unique_items_returned, 0) AS items_returned,
        COALESCE(rs.total_returned_quantity, 0) AS total_quantity,
        COALESCE(rs.max_return_amount, 0) AS max_amount,
        CASE 
            WHEN rs.avg_return_amt > 100 THEN 'Above Average'
            WHEN rs.avg_return_amt BETWEEN 50 AND 100 THEN 'Average'
            ELSE 'Below Average'
        END AS return_category,
        hvi.price_category
    FROM CustomerDetails cs
    LEFT JOIN ReturnSummary rs ON cs.c_customer_sk = rs.c_customer_sk
    LEFT JOIN HighValueItems hvi ON rs.unique_items_returned > 5 AND hvi.i_item_sk IN (
        SELECT DISTINCT sr_item_sk 
        FROM store_returns 
        WHERE sr_customer_sk = cs.c_customer_sk
    )
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.items_returned,
    f.total_quantity,
    f.max_amount,
    f.return_category,
    f.price_category
FROM FinalMetrics f
LEFT JOIN RecursiveCustomerReturns rcr ON f.c_customer_sk = rcr.wr_returning_customer_sk
WHERE rcr.rank = 1
ORDER BY f.items_returned DESC, f.max_amount DESC;
