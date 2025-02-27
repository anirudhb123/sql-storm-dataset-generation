
WITH RankedReturns AS (
    SELECT 
        wr_item_sk,
        wr_order_number,
        wr_return_quantity,
        wr_return_amt,
        wr_return_tax,
        RANK() OVER (PARTITION BY wr_item_sk ORDER BY wr_return_amt DESC) AS rn
    FROM web_returns
),
AggregatedReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_tax) AS total_return_tax
    FROM RankedReturns
    WHERE rn <= 5
    GROUP BY wr_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, 
        cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
TotalReturns AS (
    SELECT 
        i.i_item_sk,
        COALESCE(SUM(ar.total_return_quantity), 0) AS total_returned_quantity,
        COALESCE(SUM(ar.total_return_amt), 0) AS total_returned_amount
    FROM item i
    LEFT JOIN AggregatedReturns ar ON i.i_item_sk = ar.wr_item_sk
    GROUP BY i.i_item_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_credit_rating,
    CASE 
        WHEN ci.total_profit IS NULL OR ci.total_profit = 0 THEN 'No Profit'
        ELSE 'Profit Exists' 
    END AS profit_status,
    tt.total_returned_quantity,
    tt.total_returned_amount,
    CONCAT_WS(', ', i.i_item_id, i.i_item_desc) AS item_info
FROM CustomerInfo ci
JOIN TotalReturns tt ON ci.total_profit > 0
JOIN item i ON tt.i_item_sk = i.i_item_sk
WHERE 
    EXISTS (
        SELECT 1
        FROM store_sales ss
        WHERE ss.ss_item_sk = tt.i_item_sk AND ss.ss_sold_date_sk = 
        (SELECT MAX(ss2.ss_sold_date_sk) FROM store_sales ss2 WHERE ss2.ss_item_sk = ss.ss_item_sk)
    )
ORDER BY 
    ci.cd_credit_rating DESC NULLS LAST,
    tt.total_returned_amount DESC;
