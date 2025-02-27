
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ss.ss_net_profit) DESC) AS sales_rank
    FROM 
        customer c 
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
        AND c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id
),
RefundedSales AS (
    SELECT 
        sr.sr_return_quantity,
        sr.sr_item_sk,
        sr.sr_ticket_number,
        (SELECT SUM(wr.wr_return_amt) 
         FROM web_returns wr 
         WHERE wr.wr_returning_customer_sk = sr.sr_returning_customer_sk 
         AND wr.wr_return_quantity < 0) AS total_web_returns
    FROM 
        store_returns sr
    WHERE 
        sr.sr_return_quantity > 0
),
SalesWithPrediction AS (
    SELECT 
        rs.c_customer_id,
        rs.total_sales,
        rs.total_net_profit,
        COALESCE(rf.total_web_returns, 0) AS total_refunds,
        CASE 
            WHEN rs.total_net_profit - COALESCE(rf.total_web_returns, 0) < 0 THEN 'Negative Profit'
            ELSE 'Positive Profit'
        END AS profit_status
    FROM 
        RankedSales rs
    LEFT JOIN 
        (SELECT 
            sr_returning_customer_sk, 
            SUM(sr_return_quantity) AS total_web_returns
         FROM 
            Refunds
         GROUP BY 
            sr_returning_customer_sk) rf 
    ON 
        rs.c_customer_id = rf.sr_returning_customer_sk
)
SELECT 
    swp.c_customer_id,
    swp.total_sales,
    swp.total_net_profit,
    swp.total_refunds,
    swp.profit_status,
    CASE 
        WHEN swp.total_sales IS NULL OR swp.total_net_profit IS NULL THEN 'Data Insufficient'
        ELSE CAST((swp.total_net_profit - swp.total_refunds) AS DECIMAL(10,2)) 
    END AS final_profit,
    DENSE_RANK() OVER (ORDER BY swp.total_net_profit DESC) AS rank_by_profit
FROM 
    SalesWithPrediction swp
WHERE 
    swp.sales_rank <= 10
ORDER BY 
    swp.rank_by_profit, swp.total_sales DESC;
