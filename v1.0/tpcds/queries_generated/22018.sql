
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        DENSE_RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY c.c_birth_year DESC) AS marital_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > (SELECT AVG(cd_inner.cd_purchase_estimate) FROM customer_demographics cd_inner WHERE cd_inner.cd_marital_status IS NOT NULL)
),
StoreData AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_sales
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        s.s_state = 'CA'
    GROUP BY 
        s.s_store_sk, s.s_store_name
),
ItemReturns AS (
    SELECT 
        inv.inv_item_sk,
        SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_returned,
        COUNT(DISTINCT cr.cr_order_number) AS return_order_count
    FROM 
        inventory inv
    LEFT JOIN 
        catalog_returns cr ON inv.inv_item_sk = cr.cr_item_sk
    GROUP BY 
        inv.inv_item_sk
),
CustomerReturns AS (
    SELECT
        cr.returning_customer_sk,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_count,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
        CASE 
            WHEN SUM(cr.cr_return_amount) > 100 THEN 'High Returner'
            WHEN SUM(cr.cr_return_amount) BETWEEN 50 AND 100 THEN 'Medium Returner'
            ELSE 'Low Returner'
        END AS return_category
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
)
SELECT 
    rc.c_customer_sk,
    rc.c_first_name,
    rc.c_last_name,
    CASE 
        WHEN rc.marital_rank = 1 THEN 'Top Marital Status'
        ELSE 'Other Marital Status'
    END AS marital_status_group,
    sd.s_store_name,
    COALESCE(sd.total_sales, 0) AS store_total_sales,
    ir.total_returned,
    cr.distinct_return_count,
    cr.total_return_amount,
    cr.return_category
FROM 
    RankedCustomers rc
LEFT JOIN 
    StoreData sd ON rc.c_customer_sk IN (SELECT DISTINCT ss.ss_customer_sk FROM store_sales ss WHERE ss.ss_store_sk IN (SELECT s.s_store_sk FROM store s WHERE s.s_state = 'CA'))
LEFT JOIN 
    ItemReturns ir ON ir.inv_item_sk IN (SELECT ss.ss_item_sk FROM store_sales ss WHERE ss.ss_customer_sk = rc.c_customer_sk)
LEFT JOIN 
    CustomerReturns cr ON cr.returning_customer_sk = rc.c_customer_sk
WHERE 
    rc.marital_rank <= 3
ORDER BY 
    rc.c_last_name DESC, rc.c_first_name ASC, sd.total_sales DESC, ir.total_returned ASC;
