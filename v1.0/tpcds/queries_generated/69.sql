
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), HighReturnCustomers AS (
    SELECT 
        cr1.sr_customer_sk,
        cr1.total_returns,
        cr1.total_return_amount,
        cr1.avg_return_quantity,
        cr2.c_customer_id,
        cr2.c_first_name,
        cr2.c_last_name,
        cr2.c_email_address
    FROM 
        CustomerReturns cr1
    JOIN 
        customer cr2 ON cr1.sr_customer_sk = cr2.c_customer_sk
    WHERE 
        cr1.total_return_amount > 1000  -- Assuming we want high return amount
), StoreSalesSummary AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        RANK() OVER (ORDER BY SUM(ss_net_profit) DESC) AS store_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
), CustomerReturnSummary AS (
    SELECT 
        hrc.sr_customer_sk,
        hrc.total_returns,
        hrc.total_return_amount,
        hrc.avg_return_quantity,
        sss.total_profit,
        sss.total_sales
    FROM 
        HighReturnCustomers hrc
    JOIN 
        StoreSalesSummary sss ON sss.ss_store_sk = (
            SELECT 
                ss_store_sk
            FROM 
                store_sales
            WHERE 
                ss_customer_sk = hrc.sr_customer_sk
            GROUP BY 
                ss_store_sk
            ORDER BY 
                SUM(ss_net_profit) DESC
            LIMIT 1
        )
)
SELECT 
    crs.sr_customer_sk,
    crs.total_returns,
    crs.total_return_amount,
    crs.avg_return_quantity,
    COALESCE(crs.total_profit, 0) AS total_store_profit,
    COALESCE(crs.total_sales, 0) AS total_store_sales,
    CASE 
        WHEN crs.total_returns > 10 THEN 'High Return'
        WHEN crs.total_returns BETWEEN 5 AND 10 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    CustomerReturnSummary crs
WHERE 
    crs.total_returns IS NOT NULL
ORDER BY 
    crs.total_return_amount DESC
LIMIT 100;
