
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(ss_ticket_number) AS total_sales,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS sales_rank,
        1 AS level
    FROM 
        store_sales
    WHERE
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
    
    UNION ALL
    
    SELECT 
        s.s_store_sk,
        ss.total_net_profit + s.total_net_profit AS total_net_profit,
        ss.total_sales + s.total_sales AS total_sales,
        RANK() OVER (PARTITION BY s.s_store_sk ORDER BY ss.total_net_profit + s.total_net_profit DESC) AS sales_rank,
        level + 1
    FROM 
        sales_summary ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        ss.sales_rank <= 5
),
customer_returns AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(sr_ticket_number) AS total_returns
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_store_sk
),
final_summary AS (
    SELECT 
        ss.ss_store_sk,
        ss.total_net_profit,
        ss.total_sales,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_returns, 0) AS total_returns,
        (ss.total_net_profit - COALESCE(cr.total_return_amount, 0)) AS net_profit_after_returns,
        (ss.total_sales - COALESCE(cr.total_returns, 0)) AS sales_after_returns
    FROM 
        sales_summary ss
    LEFT JOIN 
        customer_returns cr ON ss.ss_store_sk = cr.sr_store_sk
)
SELECT 
    fs.ss_store_sk,
    fs.total_net_profit,
    fs.total_sales,
    fs.total_return_amount,
    fs.total_returns,
    fs.net_profit_after_returns,
    fs.sales_after_returns,
    CASE 
        WHEN fs.sales_after_returns > 0 THEN ROUND((fs.net_profit_after_returns / fs.sales_after_returns) * 100, 2)
        ELSE NULL 
    END AS profit_margin_percentage
FROM 
    final_summary fs
ORDER BY 
    fs.total_net_profit DESC;
