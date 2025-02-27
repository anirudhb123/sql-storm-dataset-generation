
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year IN (2022, 2023) 
        AND dd.d_moy BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(cr.return_amount) AS return_value
    FROM 
        catalog_returns cr
    WHERE 
        cr.returned_date_sk BETWEEN 20230101 AND 20230630
    GROUP BY 
        cr.returning_customer_sk
),
StorePerformance AS (
    SELECT 
        ss.ss_store_sk,
        COUNT(distinct ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        store_sales ss
    LEFT JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND (c.c_preferred_cust_flag = 'Y' OR c.c_first_name LIKE 'A%')
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    s.s_store_name,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(sp.total_transactions, 0) AS total_transactions,
    COALESCE(sp.total_profit, 0) AS total_profit,
    CASE 
        WHEN COALESCE(sp.total_profit, 0) = 0 THEN 'No Profit'
        ELSE FORMAT(((COALESCE(sp.total_profit, 0) - COALESCE(cr.return_value, 0)) / NULLIF(sp.total_profit, 0)) * 100, 2)
    END AS profit_margin
FROM 
    store s
LEFT JOIN 
    RankedSales r ON r.web_site_sk = s.s_store_sk
LEFT JOIN 
    CustomerReturns cr ON cr.returning_customer_sk = s.s_store_sk
LEFT JOIN 
    StorePerformance sp ON sp.ss_store_sk = s.s_store_sk
WHERE 
    s.s_state IN ('TX', 'NY', 'CA') 
    AND s.s_number_employees IS NOT NULL
ORDER BY 
    profit_margin DESC NULLS LAST;
