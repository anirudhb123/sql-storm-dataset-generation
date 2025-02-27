
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT 
        i_item_id,
        i_item_desc,
        i_current_price,
        rs.total_sales
    FROM item i
    JOIN RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE rs.sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk, 
        COUNT(*) AS total_returns,
        SUM(cr_return_amt_inc_tax) AS total_return_amount
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cr.total_returns, 
        cr.total_return_amount 
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    ti.i_item_id,
    ti.i_item_desc,
    ti.i_current_price,
    COUNT(DISTINCT ci.c_customer_id) AS total_customers,
    SUM(COALESCE(ci.total_return_amount, 0)) AS total_return_volume
FROM TopItems ti
JOIN CustomerInfo ci ON ti.total_sales > 1000 -- Example predicate for sales threshold
GROUP BY 
    ci.c_customer_id, 
    ci.cd_gender, 
    ci.cd_marital_status, 
    ti.i_item_id, 
    ti.i_item_desc, 
    ti.i_current_price
HAVING 
    SUM(COALESCE(ci.total_return_amount, 0)) > 100  -- Filtering by return amount
ORDER BY 
    total_customers DESC, 
    total_return_volume DESC;
