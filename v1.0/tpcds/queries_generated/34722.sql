
WITH RECURSIVE SalesCTE AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_profit) DESC) AS store_rank
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
),
TopStores AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_city,
        s_state,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS store_rank
    FROM 
        store s
    JOIN 
        SalesCTE sc ON s.s_store_sk = sc.s_store_sk
    WHERE 
        sc.store_rank <= 10
)
SELECT 
    ts.store_name,
    ts.number_employees,
    ts.city,
    ts.state,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_value, 0) AS total_return_value,
    CASE 
        WHEN COALESCE(cr.total_return_value, 0) > 1000 THEN 'High Return Value'
        WHEN COALESCE(cr.total_return_value, 0) BETWEEN 500 AND 1000 THEN 'Medium Return Value'
        ELSE 'Low Return Value' 
    END AS return_value_category
FROM 
    TopStores ts
LEFT JOIN 
    CustomerReturns cr ON cr.returned_date_sk = (SELECT MAX(cr.returned_date_sk) FROM CustomerReturns)
ORDER BY 
    ts.store_rank;
