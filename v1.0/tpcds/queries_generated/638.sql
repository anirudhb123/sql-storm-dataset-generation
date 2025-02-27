
WITH RankedSales AS (
    SELECT 
        ss.s_store_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        RANK() OVER(PARTITION BY ss.s_store_sk ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ss.s_store_sk, ss.ss_sold_date_sk
), 
CustomerReturnStats AS (
    SELECT 
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amount,
        SUM(sr_net_loss) AS total_net_loss
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)
SELECT 
    s.s_store_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(cr.total_net_loss, 0) AS total_net_loss,
    DENSE_RANK() OVER(ORDER BY COALESCE(rs.total_sales, 0) DESC) AS sales_rank
FROM 
    store s
LEFT JOIN 
    RankedSales rs ON s.s_store_sk = rs.s_store_sk
LEFT JOIN 
    CustomerReturnStats cr ON s.s_store_sk = cr.sr_store_sk
WHERE 
    s.s_number_employees IS NOT NULL
ORDER BY 
    sales_rank;
