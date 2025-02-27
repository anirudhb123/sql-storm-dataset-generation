
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IS NOT NULL
    GROUP BY 
        sr_customer_sk
), 
TopCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cr.return_count,
        cr.total_return_quantity,
        cr.total_return_amt,
        RANK() OVER (ORDER BY cr.total_return_amt DESC) AS rank
    FROM 
        CustomerReturns cr
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cc.cc_name,
    ca.ca_city,
    ca.ca_state,
    tc.total_return_quantity,
    tc.total_return_amt,
    tc.return_count 
FROM 
    customer c 
JOIN 
    CustomerAddress ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    call_center cc ON cc.cc_call_center_sk = (SELECT cc_call_center_sk 
                                               FROM call_center 
                                               WHERE cc_open_date_sk <= (SELECT MAX(d_date_sk) 
                                                                          FROM date_dim 
                                                                          WHERE d_date = CURRENT_DATE)
                                               LIMIT 1)
JOIN 
    TopCustomers tc ON c.c_customer_sk = tc.sr_customer_sk
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_return_amt DESC;
