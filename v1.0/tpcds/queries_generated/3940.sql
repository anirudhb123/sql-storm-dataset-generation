
WITH RankedReturns AS (
    SELECT 
        wr.refunded_customer_sk,
        wr.web_page_sk,
        SUM(wr.return_quantity) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY wr.refunded_customer_sk ORDER BY SUM(wr.return_quantity) DESC) AS rn
    FROM 
        web_returns wr
    GROUP BY 
        wr.refunded_customer_sk, wr.web_page_sk
),
HighReturnCustomers AS (
    SELECT 
        rr.refunded_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(rr.web_page_sk) AS return_pages_count
    FROM 
        RankedReturns rr
    JOIN 
        customer c ON rr.refunded_customer_sk = c.c_customer_sk
    WHERE 
        rr.rn = 1 AND rr.total_returned > 5
    GROUP BY 
        rr.refunded_customer_sk, c.c_first_name, c.c_last_name
),
StoreSalesSummary AS (
    SELECT 
        ss.store_sk,
        SUM(ss.net_profit) AS total_profit,
        SUM(ss.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ticket_number) AS total_transactions
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.store_sk = s.s_store_sk
    WHERE 
        s.s_state = 'CA' AND ss.sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ss.store_sk
)
SELECT 
    hrc.refunded_customer_sk,
    hrc.c_first_name,
    hrc.c_last_name,
    s.total_profit,
    s.total_sales,
    CASE 
        WHEN s.total_profit > 10000 THEN 'High Profit'
        WHEN s.total_profit BETWEEN 5000 AND 10000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    HighReturnCustomers hrc
LEFT JOIN 
    StoreSalesSummary s ON hrc.refunded_customer_sk = s.store_sk
WHERE 
    hrc.return_pages_count > 1
ORDER BY 
    total_profit DESC, hrc.c_last_name, hrc.c_first_name;
