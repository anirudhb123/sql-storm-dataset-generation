
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        NULL AS parent_customer_sk
    FROM customer c
    WHERE c.c_birth_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        ch.c_customer_sk AS parent_customer_sk
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
), 
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
MarchSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS march_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_month_seq = 3 AND d.d_year = 2023
    GROUP BY ws.ws_bill_customer_sk
),
FinalSummary AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.c_birth_year,
        COALESCE(ss.total_net_profit, 0) AS total_store_sales_profit,
        COALESCE(ms.march_net_profit, 0) AS total_march_web_sales_profit,
        CASE 
            WHEN COALESCE(ms.march_net_profit, 0) > 0 THEN 'Yes'
            ELSE 'No'
        END AS made_sales_in_march
    FROM CustomerHierarchy ch
    LEFT JOIN SalesSummary ss ON ch.c_customer_sk = ss.c_customer_sk
    LEFT JOIN MarchSales ms ON ch.c_customer_sk = ms.ws_bill_customer_sk
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.c_birth_year,
    f.total_store_sales_profit,
    f.total_march_web_sales_profit,
    f.made_sales_in_march
FROM FinalSummary f
WHERE f.total_store_sales_profit > 1000
ORDER BY f.total_store_sales_profit DESC, f.c_last_name ASC;
