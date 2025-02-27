
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk
    UNION ALL
    SELECT 
        d.d_date_sk,
        COALESCE(s.order_count, 0) + r.order_count AS order_count,
        COALESCE(s.total_profit, 0) + r.total_profit AS total_profit
    FROM 
        sales_cte s
    JOIN 
        date_dim d ON s.ws_sold_date_sk = d.d_date_sk + 1
    LEFT JOIN 
        (SELECT 
            ws_sold_date_sk, COUNT(ws_order_number) AS order_count, SUM(ws_net_profit) AS total_profit
         FROM 
            web_sales
         GROUP BY 
            ws_sold_date_sk) r ON r.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim)
)
SELECT 
    d.d_date AS sales_date,
    s.order_count,
    s.total_profit,
    (SELECT SUM(ws_ext_sales_price) 
     FROM web_sales 
     WHERE ws_sold_date_sk <= d.d_date_sk) AS cumulative_sales,
    (SELECT COUNT(DISTINCT c_customer_sk) 
     FROM customer 
     WHERE c_current_addr_sk IS NOT NULL 
       AND c_preferred_cust_flag = 'Y') AS customer_count,
    CASE 
        WHEN s.total_profit > 10000 THEN 'High'
        WHEN s.total_profit > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM 
    sales_cte s
JOIN 
    date_dim d ON s.ws_sold_date_sk = d.d_date_sk
ORDER BY 
    d.d_date;
