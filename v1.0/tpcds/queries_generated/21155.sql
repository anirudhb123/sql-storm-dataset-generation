
WITH RankedItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY i.i_current_price DESC) AS rn
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND 
        (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_returning_customer_sk
),
HighSpendingCustomers AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_paid_inc_tax) > 1000
),
PopularReturns AS (
    SELECT 
        cr_item_sk,
        COUNT(*) AS popular_return_count
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
    HAVING 
        COUNT(*) > 10
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN hsc.total_spent IS NOT NULL THEN 'High Spender'
        ELSE 'Regular Customer'
    END AS customer_type,
    ri.i_item_desc,
    ri.i_current_price
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
LEFT JOIN 
    HighSpendingCustomers hsc ON c.c_customer_sk = hsc.ws_bill_customer_sk
LEFT JOIN 
    RankedItems ri ON ri.rn <= 5 -- Get top 5 items by price
LEFT JOIN 
    PopularReturns pr ON pr.cr_item_sk = ri.i_item_sk
WHERE 
    c.c_birth_year IS NOT NULL AND 
    c.c_birth_month IS NOT NULL AND 
    (c.c_birth_day BETWEEN 1 AND 31)
ORDER BY 
    total_return_amt DESC 
LIMIT 50;
