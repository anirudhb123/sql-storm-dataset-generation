
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(sr.ticket_number) AS total_store_returns,
        SUM(sr.return_amt) AS total_store_return_amount,
        SUM(sr.return_tax) AS total_store_return_tax,
        SUM(sr.return_net_loss) AS total_store_net_loss
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
WebReturns AS (
    SELECT 
        wr.returning_customer_sk,
        COUNT(wr.order_number) AS total_web_returns,
        SUM(wr.return_amt) AS total_web_return_amount,
        SUM(wr.return_tax) AS total_web_return_tax,
        SUM(wr.net_loss) AS total_web_net_loss
    FROM 
        web_returns wr
    GROUP BY 
        wr.returning_customer_sk
),
ReturnedCustomers AS (
    SELECT 
        cr.c_customer_sk,
        cr.c_first_name,
        cr.c_last_name,
        COALESCE(cr.total_store_returns, 0) AS total_store_returns,
        COALESCE(cr.total_store_return_amount, 0) AS total_store_return_amount,
        COALESCE(cr.total_store_return_tax, 0) AS total_store_return_tax,
        COALESCE(cr.total_store_net_loss, 0) AS total_store_net_loss,
        COALESCE(wr.total_web_returns, 0) AS total_web_returns,
        COALESCE(wr.total_web_return_amount, 0) AS total_web_return_amount,
        COALESCE(wr.total_web_return_tax, 0) AS total_web_return_tax,
        COALESCE(wr.total_web_net_loss, 0) AS total_web_net_loss
    FROM 
        CustomerReturns cr
    FULL OUTER JOIN 
        WebReturns wr ON cr.c_customer_sk = wr.returning_customer_sk
),
FinalReport AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.total_store_returns + rc.total_web_returns AS total_returns,
        rc.total_store_return_amount + rc.total_web_return_amount AS total_return_amount,
        rc.total_store_return_tax + rc.total_web_return_tax AS total_return_tax,
        rc.total_store_net_loss + rc.total_web_net_loss AS total_net_loss
    FROM 
        ReturnedCustomers rc
),
RankedReturns AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_returns DESC) AS return_rank
    FROM 
        FinalReport 
)
SELECT 
    c.c_customer_id,
    fr.c_first_name,
    fr.c_last_name,
    fr.total_returns,
    fr.total_return_amount,
    fr.total_return_tax,
    fr.total_net_loss,
    CASE 
        WHEN fr.total_returns > 0 THEN 'Returning Customer'
        ELSE 'No Returns'
    END AS return_status
FROM 
    RankedReturns fr
JOIN 
    customer c ON fr.c_customer_sk = c.c_customer_sk
WHERE 
    fr.return_rank <= 10
ORDER BY 
    fr.return_rank;
