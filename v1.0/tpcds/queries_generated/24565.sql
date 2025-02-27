
WITH RankedReturns AS (
    SELECT 
        COALESCE(sr_customer_sk, cr_returning_customer_sk) AS customer_sk,
        SUM(COALESCE(sr_return_quantity, 0) + COALESCE(cr_return_quantity, 0)) AS total_return_quantity,
        SUM(COALESCE(sr_return_amt, 0) + COALESCE(cr_return_amount, 0)) AS total_return_amt,
        SUM(COALESCE(sr_return_tax, 0) + COALESCE(cr_return_tax, 0)) AS total_return_tax,
        DENSE_RANK() OVER (PARTITION BY COALESCE(sr_customer_sk, cr_returning_customer_sk) ORDER BY SUM(COALESCE(sr_return_quantity, 0) + COALESCE(cr_return_quantity, 0)) DESC) AS rank
    FROM 
        store_returns SR
    FULL OUTER JOIN 
        catalog_returns CR ON SR.cr_order_number = CR.cr_order_number AND SR.sr_item_sk = CR.cr_item_sk
    GROUP BY 
        COALESCE(sr_customer_sk, cr_returning_customer_sk)
), FilteredReturns AS (
    SELECT 
        *,
        CASE 
            WHEN total_return_amt > 1000 THEN 'High Returner'
            WHEN total_return_amt BETWEEN 500 AND 1000 THEN 'Medium Returner'
            ELSE 'Low Returner'
        END AS returner_category
    FROM 
        RankedReturns
    WHERE 
        rank <= 10
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    fr.returner_category,
    fr.total_return_quantity,
    fr.total_return_amt,
    fr.total_return_tax
FROM 
    FilteredReturns fr
LEFT JOIN 
    customer c ON fr.customer_sk = c.c_customer_sk
WHERE 
    (fr.total_return_quantity IS NOT NULL AND fr.total_return_quantity > 0) OR 
    (fr.total_return_amt IS NOT NULL AND fr.total_return_amt > 500)
ORDER BY 
    fr.total_return_amt DESC, 
    fr.total_return_quantity ASC
LIMIT 20;
