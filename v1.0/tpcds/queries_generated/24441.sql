
WITH RecursiveSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
HighProfitCustomers AS (
    SELECT 
        rs.ws_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        rs.total_profit,
        ROW_NUMBER() OVER (PARTITION BY rs.ws_bill_customer_sk ORDER BY rs.total_profit DESC) AS rnk
    FROM 
        RecursiveSales rs
    JOIN 
        customer c ON rs.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        rs.total_profit IS NOT NULL
),
FilteredIncome AS (
    SELECT 
        h.hd_demo_sk,
        ib.ib_income_band_sk,
        CASE 
            WHEN h.hd_buy_potential = 'High' THEN 'Premium'
            ELSE 'Standard'
        END AS customer_type
    FROM 
        household_demographics h
    LEFT JOIN 
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ib.ib_upper_bound > 0
),
AggregatedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    hpc.ws_bill_customer_sk,
    hpc.c_first_name,
    hpc.c_last_name,
    COALESCE(SUM(CASE WHEN wr.return_count > 0 THEN wr.total_return_amt ELSE 0 END), 0) AS total_return_amount,
    CASE 
        WHEN hpc.rnk = 1 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    HighProfitCustomers hpc
FULL OUTER JOIN 
    AggregatedReturns wr ON hpc.ws_bill_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN 
    FilteredIncome fi ON hpc.ws_bill_customer_sk = fi.hd_demo_sk
WHERE 
    (fi.customer_type = 'Premium' OR hpc.total_profit BETWEEN 1000 AND 5000)
    AND (hpc.total_orders IS NOT NULL OR wr.return_count > 0)
GROUP BY 
    hpc.ws_bill_customer_sk, hpc.c_first_name, hpc.c_last_name, hpc.rnk
HAVING 
    total_return_amount > 100 OR COUNT(hpc.total_orders) > 5
ORDER BY 
    hpc.total_profit DESC NULLS LAST, 
    hpc.c_last_name ASC;
