
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        1 AS level
    FROM 
        item i
    WHERE 
        i.i_item_sk IS NOT NULL

    UNION ALL

    SELECT 
        ih.i_item_sk,
        CONCAT(ih.i_item_desc, ' > ', i.i_item_desc),
        ih.level + 1
    FROM 
        ItemHierarchy ih
    JOIN 
        item i ON ih.i_item_sk = i.i_item_sk
    WHERE 
        ih.level < 3  -- Limiting recursion to 3 levels deep
),
CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount,
        COALESCE(SUM(sr.sr_return_tax), 0) AS total_return_tax,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY COUNT(DISTINCT sr.sr_ticket_number) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cr.total_returns,
        cr.total_return_amount,
        cr.total_return_tax
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.c_customer_id = c.c_customer_id
    WHERE 
        cr.rn <= 10  -- Retrieve top 10 customers by total returns
)
SELECT 
    ic.i_item_desc,
    ic.level,
    tc.c_customer_id,
    tc.total_returns,
    tc.total_return_amount,
    tc.total_return_tax,
    (SELECT 
        COUNT(*) 
     FROM 
        store_sales ss 
     WHERE 
        ss.ss_item_sk = ic.i_item_sk AND ss.ss_net_paid > 0) AS sales_count,
    (SELECT 
        SUM(ss.ss_net_paid) 
     FROM 
        store_sales ss 
     WHERE 
        ss.ss_item_sk = ic.i_item_sk) AS total_sales
FROM 
    ItemHierarchy ic
LEFT JOIN 
    TopCustomers tc ON ic.i_item_sk = tc.total_returns
ORDER BY 
    ic.level, total_return_amount DESC;
