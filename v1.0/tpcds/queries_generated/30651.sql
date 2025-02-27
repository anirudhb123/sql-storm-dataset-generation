
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        sr_item_sk,
        sr_ticket_number,
        1 AS return_level
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    UNION ALL
    SELECT 
        sr_customer_sk,
        sr.return_quantity + cr.returning_quantity,
        sr.return_amt + cr.return_amt,
        sr.return_tax + cr.return_tax,
        sr_item_sk,
        sr_ticket_number,
        return_level + 1
    FROM 
        CustomerReturns sr
    JOIN 
        catalog_returns cr ON sr.sr_item_sk = cr.cr_item_sk AND sr.sr_ticket_number = cr.cr_order_number
    WHERE 
        sr.return_level < 5
),
TotalReturns AS (
    SELECT 
        cr.sr_customer_sk,
        SUM(cr.sr_return_quantity) AS total_return_quantity,
        SUM(cr.sr_return_amt) AS total_return_amt,
        SUM(cr.sr_return_tax) AS total_return_tax
    FROM 
        CustomerReturns cr
    GROUP BY 
        cr.sr_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        dd.d_year,
        dd.d_month_seq,
        COALESCE(tr.total_return_quantity, 0) AS total_returns,
        COALESCE(tr.total_return_amt, 0) AS total_return_amt,
        COALESCE(tr.total_return_tax, 0) AS total_return_tax
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        TotalReturns tr ON c.c_customer_sk = tr.sr_customer_sk
    LEFT JOIN 
        date_dim dd ON c.c_first_sales_date_sk = dd.d_date_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.d_year,
    CASE 
        WHEN ci.d_month_seq IS NULL THEN 'No First Sale'
        ELSE TO_CHAR(TO_DATE(1, 'MM'), 'Month') || ' ' || ci.d_year
    END AS first_sale_month_year,
    'Total Returns: ' || ci.total_returns || ', Amount: ' || ci.total_return_amt || ', Tax: ' || ci.total_return_tax AS returns_summary
FROM 
    CustomerInfo ci
WHERE 
    ci.total_returns > 0 OR ci.d_month_seq IS NULL
ORDER BY 
    ci.total_returns DESC, 
    ci.c_last_name ASC
LIMIT 100;
