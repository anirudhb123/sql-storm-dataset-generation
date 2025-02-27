
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
    UNION ALL
    SELECT 
        cr_returning_customer_sk,
        total_returns + COALESCE(SUM(cr_return_quantity), 0),
        return_count + COALESCE(COUNT(DISTINCT cr_order_number), 0)
    FROM 
        catalog_returns
    JOIN 
        CustomerReturns ON cr_returning_customer_sk = sr_customer_sk
    GROUP BY 
        cr_returning_customer_sk, total_returns, return_count
),
TopReturns AS (
    SELECT 
        sr_customer_sk,
        total_returns,
        return_count,
        ROW_NUMBER() OVER (ORDER BY total_returns DESC) AS rn
    FROM 
        CustomerReturns
),
AddressCounts AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    T.rn,
    T.sr_customer_sk,
    T.total_returns,
    T.return_count,
    AC.address_count,
    CD.cd_gender,
    CD.cd_marital_status,
    I.i_item_desc,
    SUM(CASE 
            WHEN S.ss_item_sk IS NOT NULL THEN S.ss_net_profit 
            ELSE 0 
        END) AS total_net_profit
FROM 
    TopReturns T
JOIN 
    customer_demographics CD ON T.sr_customer_sk = CD.cd_demo_sk
LEFT JOIN 
    store_sales S ON T.sr_customer_sk = S.ss_customer_sk
LEFT JOIN 
    item I ON S.ss_item_sk = I.i_item_sk 
JOIN 
    AddressCounts AC ON T.sr_customer_sk = AC.c_customer_sk
WHERE 
    T.return_count > 5 AND (CD.cd_marital_status = 'M' OR CD.cd_gender = 'F')
GROUP BY 
    T.rn, T.sr_customer_sk, T.total_returns, T.return_count, AC.address_count, CD.cd_gender, CD.cd_marital_status, I.i_item_desc
HAVING 
    SUM(S.ss_net_profit) > 1000
ORDER BY 
    T.total_returns DESC;
