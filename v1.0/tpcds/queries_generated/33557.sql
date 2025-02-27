
WITH RECURSIVE SalesData AS (
    SELECT 
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    GROUP BY 
        ss_sold_date_sk
    
    UNION ALL
    
    SELECT 
        sd.ss_sold_date_sk,
        sd.total_sales + COALESCE(sd2.total_sales, 0),
        sd.total_transactions + COALESCE(sd2.total_transactions, 0)
    FROM 
        SalesData sd
    LEFT JOIN 
        SalesData sd2 ON sd.ss_sold_date_sk + 1 = sd2.ss_sold_date_sk
    WHERE 
        sd.ss_sold_date_sk < (SELECT MAX(ss_sold_date_sk) FROM store_sales)
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws_net_profit), 0) AS total_web_sales,
        COALESCE(SUM(ss_net_profit), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cust.c_first_name,
    cust.c_last_name,
    cust.cd_gender,
    cust.cd_marital_status,
    sd.total_sales,
    cust.total_web_sales,
    cust.total_store_sales,
    CASE 
        WHEN cust.total_web_sales > cust.total_store_sales THEN 'Web'
        WHEN cust.total_store_sales > cust.total_web_sales THEN 'Store'
        ELSE 'Equal'
    END AS preferred_channel
FROM 
    CustomerData cust
JOIN 
    SalesData sd ON sd.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
WHERE 
    cust.total_web_sales IS NOT NULL
ORDER BY 
    preferred_channel DESC, cust.c_last_name, cust.c_first_name;
