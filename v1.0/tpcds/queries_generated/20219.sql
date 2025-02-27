
WITH RankedReturns AS (
    SELECT 
        COALESCE(sr_customer_sk, wr_returned_customer_sk) AS customer_id,
        COALESCE(sr_return_quantity, wr_return_quantity) AS total_returns,
        COALESCE(sr_return_amt, wr_return_amt) AS return_amount,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(sr_customer_sk, wr_returned_customer_sk) ORDER BY COALESCE(sr_return_amount, wr_return_amt) DESC) AS rank
    FROM 
        store_returns sr
    FULL OUTER JOIN 
        web_returns wr ON sr_item_sk = wr_item_sk AND sr_ticket_number = wr_order_number
    WHERE 
        COALESCE(sr_return_quantity, wr_return_quantity) IS NOT NULL
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(rr.total_returns) AS total_returned_items,
    SUM(rr.return_amount) AS total_returned_value,
    CASE 
        WHEN SUM(rr.total_returns) > 10 THEN 'High Return Customer' 
        WHEN SUM(rr.total_returns) BETWEEN 5 AND 10 THEN 'Medium Return Customer'
        ELSE 'Low Return Customer'
    END AS return_status,
    DENSE_RANK() OVER (ORDER BY SUM(rr.return_amount) DESC) AS value_rank,
    COUNT() FILTER (WHERE rr.total_returns IS NULL) AS null_return_count
FROM 
    RankedReturns rr
JOIN 
    CustomerDetails cd ON rr.customer_id = cd.c_customer_id
WHERE 
    rr.rank = 1
GROUP BY 
    cd.c_customer_id, cd.cd_gender, cd.cd_marital_status
HAVING 
    SUM(rr.return_amount) > (SELECT AVG(return_amount)
                             FROM RankedReturns rr_inner
                             WHERE rr_inner.customer_id IS NOT NULL)
ORDER BY 
    total_returned_value DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM CustomerDetails) / 2;
