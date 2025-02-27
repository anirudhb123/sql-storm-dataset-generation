
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk, 
        s_store_name,
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s_store_sk, s_store_name
    HAVING 
        SUM(ss_net_profit) > 0
    UNION ALL
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.total_profit + COALESCE((SELECT SUM(ss_net_profit) 
                                      FROM store_sales 
                                      WHERE ss_store_sk = sh.s_store_sk 
                                      AND ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) 
                                                                    FROM date_dim 
                                                                    WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE) 
                                                                    AND d_month_seq = EXTRACT(MONTH FROM CURRENT_DATE)) 
                                                                    AND (SELECT MAX(d_date_sk) 
                                                                         FROM date_dim 
                                                                         WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE) 
                                                                         AND d_month_seq = EXTRACT(MONTH FROM CURRENT_DATE)), 0), 0
    FROM 
        sales_hierarchy sh
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COUNT(DISTINCT wr_order_number) AS total_web_returns,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(wr_return_quantity) AS avg_return_quantity,
    RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(wr_return_amt) DESC) AS return_rank
FROM 
    web_returns wr
LEFT JOIN 
    customer c ON wr_returning_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1)
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    COUNT(DISTINCT wr_order_number) > 0
ORDER BY 
    total_return_amount DESC
LIMIT 10;
