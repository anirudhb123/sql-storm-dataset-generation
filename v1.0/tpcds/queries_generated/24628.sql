
WITH RankedReturns AS (
    SELECT 
        sr.customer_sk,
        COUNT(sr.returned_date_sk) AS return_count,
        SUM(sr.return_amt) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY sr.customer_sk ORDER BY SUM(sr.return_amt) DESC) AS rank
    FROM 
        store_returns sr
    GROUP BY 
        sr.customer_sk
), 
StoreSummary AS (
    SELECT 
        s.store_sk,
        s.store_name,
        AVG(ss.net_profit) AS avg_net_profit,
        MAX(ss.list_price) AS max_list_price,
        SUM(ss.quantity) AS total_sales_quantity
    FROM 
        store_sales ss 
    JOIN 
        store s ON ss.store_sk = s.store_sk 
    GROUP BY 
        s.store_sk, 
        s.store_name
), 
IncomeRange AS (
    SELECT 
        hd.income_band_sk,
        COUNT(DISTINCT c.customer_sk) AS customer_count
    FROM 
        household_demographics hd 
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        hd.income_band_sk
    HAVING 
        COUNT(DISTINCT c.customer_sk) > 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(rr.return_count, 0) AS total_returns,
    sr.store_name,
    sr.avg_net_profit,
    ir.customer_count,
    CASE WHEN rr.return_count IS NULL THEN 'No Returns' ELSE 'Has Returns' END AS return_status,
    NULLIF(AVG(NULLIF(sr.avg_net_profit, 0)), 0) AS adjusted_avg_profit
FROM 
    customer c 
LEFT JOIN 
    RankedReturns rr ON c.c_customer_sk = rr.customer_sk AND rr.rank = 1
JOIN 
    StoreSummary sr ON sr.total_sales_quantity > 100
FULL OUTER JOIN 
    IncomeRange ir ON ir.income_band_sk = c.c_current_hdemo_sk
WHERE 
    c.c_birth_year >= 1980
    AND (c.c_preferred_cust_flag IS NULL OR c.c_preferred_cust_flag = 'Y')
ORDER BY 
    total_returns DESC, 
    sr.avg_net_profit DESC 
LIMIT 100;
