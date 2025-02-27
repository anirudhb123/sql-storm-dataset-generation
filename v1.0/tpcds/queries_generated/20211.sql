
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) as rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit > 0
),
TotalCustomerReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns
    FROM 
        web_returns wr
    LEFT JOIN 
        store_returns sr ON wr.wr_returning_customer_sk = sr.sr_customer_sk
    GROUP BY 
        wr.wr_returning_customer_sk
),
AverageReturn AS (
    SELECT 
        wr_returning_customer_sk,
        COALESCE(total_web_returns, 0) AS total_web_returns,
        COALESCE(total_store_returns, 0) AS total_store_returns,
        CASE 
            WHEN COALESCE(total_web_returns, 0) = 0 THEN NULL 
            ELSE (COALESCE(total_store_returns, 0) * 1.0 / COALESCE(total_web_returns, 0))
        END AS return_ratio
    FROM 
        TotalCustomerReturns
),
MaxReturnRatio AS (
    SELECT 
        wd.wd_return_ratio,
        ROW_NUMBER() OVER (ORDER BY wd.wd_return_ratio DESC) as rank
    FROM ( 
        SELECT 
            AVG(return_ratio) AS wd_return_ratio 
        FROM 
            AverageReturn 
        WHERE 
            return_ratio IS NOT NULL
        GROUP BY 
            wr_returning_customer_sk
    ) wd
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ra.rank_sales,
    m.wd_return_ratio,
    CASE 
        WHEN m.rank = 1 THEN 'Top Returning Customer'
        ELSE 'Regular Customer'
    END AS customer_rank
FROM 
    customer c
JOIN 
    RankedSales ra ON c.c_customer_sk = ra.web_site_sk
JOIN 
    MaxReturnRatio m ON ra.rank_sales = 1
WHERE 
    c.c_birth_year IS NOT NULL
    AND (c.c_preferred_cust_flag = 'Y' OR c.c_email_address IS NULL)
ORDER BY 
    c.c_customer_id, ra.ws_order_number;
