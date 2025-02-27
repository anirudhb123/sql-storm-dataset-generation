
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_item_sk) AS total_returned_items,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cr.c_customer_sk,
        cr.total_returned_items,
        cr.total_return_amount,
        DENSE_RANK() OVER (ORDER BY cr.total_return_amount DESC) AS return_rank
    FROM 
        CustomerReturns cr
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    tc.total_returned_items,
    tc.total_return_amount,
    COALESCE(tc.return_rank, 'No Returns') AS return_rank,
    CASE 
        WHEN tc.total_return_amount > 1000 THEN 'High Value'
        WHEN tc.total_return_amount BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS return_value_category,
    ca.ca_city,
    ca.ca_state
FROM 
    customer c
LEFT JOIN 
    TopCustomers tc ON c.c_customer_sk = tc.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    (tc.total_returned_items IS NOT NULL OR c.c_customer_sk IS NULL)
    AND (ca.ca_state = 'CA' OR ca.ca_state IS NULL)
ORDER BY 
    tc.total_return_amount DESC NULLS LAST;
