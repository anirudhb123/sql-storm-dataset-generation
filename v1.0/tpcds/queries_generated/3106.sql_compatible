
WITH CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned_qty,
        SUM(cr.return_amount) AS total_returned_amt,
        SUM(cr.return_tax) AS total_returned_tax,
        COUNT(DISTINCT cr.order_number) AS return_order_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 10000
),
StoreSales AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss.ss_store_sk
)

SELECT 
    s.s_store_id,
    s.s_store_name,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(cs.total_returned_qty, 0) AS total_returned_qty,
    COALESCE(cs.total_returned_amt, 0) AS total_returned_amt,
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status
FROM 
    store s
LEFT JOIN 
    StoreSales ss ON s.s_store_sk = ss.ss_store_sk
LEFT JOIN 
    CustomerReturns cs ON cs.returning_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = s.s_store_sk LIMIT 1)
JOIN 
    HighValueCustomers hvc ON hvc.gender_rank <= 5
WHERE 
    s.s_market_class IS NOT NULL
ORDER BY 
    total_sales DESC, total_returned_amt DESC;
