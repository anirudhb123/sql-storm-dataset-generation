
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_cr_return_qty,
        SUM(cr_return_amount) AS total_cr_return_amt,
        COUNT(DISTINCT cr_order_number) AS cr_order_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
WebReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_wr_return_qty,
        SUM(wr_return_amt) AS total_wr_return_amt,
        COUNT(DISTINCT wr_order_number) AS wr_order_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
AllReturns AS (
    SELECT 
        COALESCE(cr.returning_customer_sk, wr.returning_customer_sk) AS returning_customer_sk,
        COALESCE(cr.total_cr_return_qty, 0) AS cr_return_qty,
        COALESCE(cr.total_cr_return_amt, 0) AS cr_return_amt,
        COALESCE(wr.total_wr_return_qty, 0) AS wr_return_qty,
        COALESCE(wr.total_wr_return_amt, 0) AS wr_return_amt,
        cr_order_count,
        wr_order_count
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        WebReturns wr 
    ON 
        cr.returning_customer_sk = wr.returning_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
)
SELECT 
    cust.c_first_name,
    cust.c_last_name,
    COALESCE(ar.cr_return_qty, 0) AS catalog_return_qty,
    COALESCE(ar.wr_return_qty, 0) AS web_return_qty,
    (ar.cr_return_qty + ar.wr_return_qty) AS total_return_qty,
    CASE 
        WHEN ar.cr_return_qty > ar.wr_return_qty THEN 'More Catalog Returns'
        WHEN ar.cr_return_qty < ar.wr_return_qty THEN 'More Web Returns'
        ELSE 'Equal Returns'
    END AS return_type,
    CASE 
        WHEN cust.rn = 1 AND cd.cd_gender = 'M' THEN 'Top Male Customer'
        WHEN cust.rn = 1 AND cd.cd_gender = 'F' THEN 'Top Female Customer'
        ELSE 'Regular Customer'
    END AS customer_rank
FROM 
    AllReturns ar
JOIN 
    CustomerDemographics cust ON ar.returning_customer_sk = cust.c_customer_sk
WHERE 
    (ar.cr_return_qty + ar.wr_return_qty) > 0
AND 
    (EXISTS (SELECT 1 FROM inventory WHERE inv_item_sk IN 
        (SELECT sr_item_sk FROM store_returns WHERE sr_return_quantity > 0)
    ) OR EXISTS (SELECT 1 FROM inventory WHERE inv_item_sk IN 
        (SELECT wr_item_sk FROM web_returns WHERE wr_return_quantity > 0)
    ))
ORDER BY 
    total_return_qty DESC,
    return_type ASC;
