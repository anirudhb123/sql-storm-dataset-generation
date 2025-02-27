
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.item_sk,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) as rn
    FROM
        web_sales ws
    WHERE
        ws.sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND 
                                (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
HighValueWebSales AS (
    SELECT 
        R.web_site_sk,
        R.item_sk,
        R.net_profit
    FROM 
        RankedSales R
    WHERE 
        R.rn <= 5
),
TotalReturns AS (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.refunded_customer_sk
),
CustomerMetrics AS (
    SELECT 
        C.c_customer_id,
        COALESCE(T.total_return_amt, 0) AS total_return_amt,
        SUM(CASE WHEN CD.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        COUNT(DISTINCT C.c_email_address) AS unique_emails
    FROM 
        customer C
    LEFT JOIN 
        TotalReturns T ON C.c_customer_sk = T.refunded_customer_sk
    LEFT JOIN 
        customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
    GROUP BY 
        C.c_customer_id
)
SELECT 
    H.web_site_sk,
    H.item_sk,
    C.c_customer_id,
    C.total_return_amt,
    C.male_count,
    C.unique_emails
FROM 
    HighValueWebSales H
JOIN 
    CustomerMetrics C ON H.web_site_sk = (SELECT MAX(ws.web_site_sk) FROM web_sales ws WHERE ws.item_sk = H.item_sk)
WHERE 
    C.total_return_amt > 1000
    AND (C.male_count + C.unique_emails) / NULLIF(C.unique_emails, 0) < 2
ORDER BY 
    H.web_site_sk, H.item_sk, C.total_return_amt DESC;
