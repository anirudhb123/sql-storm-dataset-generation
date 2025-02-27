
WITH RECURSIVE CustomerReturnData AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    UNION ALL
    SELECT 
        sr.returned_date_sk,
        sr.item_sk,
        sr.customer_sk,
        sr.return_quantity,
        sr.return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr.customer_sk ORDER BY sr.returned_date_sk DESC)
    FROM 
        store_returns sr
    JOIN 
        CustomerReturnData crd ON sr.customer_sk = crd.sr_customer_sk
    WHERE 
        crd.rn < 5
),
AggregatedReturnData AS (
    SELECT 
        crd.sr_customer_sk,
        SUM(crd.sr_return_quantity) AS total_return_quantity,
        SUM(crd.sr_return_amt) AS total_return_amt
    FROM 
        CustomerReturnData crd
    GROUP BY 
        crd.sr_customer_sk
),
TopCustomers AS (
    SELECT 
        cust.c_customer_sk,
        COALESCE(CR.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(CR.total_return_amt, 0) AS total_return_amt,
        RANK() OVER (ORDER BY COALESCE(CR.total_return_quantity, 0) DESC) AS rank
    FROM 
        customer cust
    LEFT JOIN 
        AggregatedReturnData CR ON cust.c_customer_sk = CR.sr_customer_sk
    WHERE 
        cust.c_birth_year IS NOT NULL 
        AND cust.c_birth_month BETWEEN 1 AND 12
)
SELECT 
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    t.total_return_quantity,
    t.total_return_amt,
    CASE 
        WHEN t.rank <= 10 THEN 'Top 10% Customers'
        ELSE 'Other'
    END AS customer_type,
    CONCAT(cu.c_first_name, ' ', cu.c_last_name) AS full_name,
    CASE 
        WHEN cu.c_current_cdemo_sk IS NULL THEN 'No Demographic Info'
        ELSE 'Demographic Info Present'
    END AS demo_info_status
FROM 
    TopCustomers t
JOIN 
    customer cu ON t.c_customer_sk = cu.c_customer_sk
WHERE 
    (t.total_return_quantity > 0 OR t.total_return_amt > 0)
    AND (cu.c_preferred_cust_flag IS NULL OR cu.c_preferred_cust_flag = 'Y')
ORDER BY 
    t.total_return_quantity DESC,
    t.total_return_amt DESC;
