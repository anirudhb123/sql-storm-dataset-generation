
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss_store_sk, 
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        RANK() OVER (ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
    HAVING 
        SUM(ss_net_profit) > 1000
),
high_performance_stores AS (
    SELECT 
        s_store_sk, 
        s_store_name, 
        total_profit,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY total_sales ORDER BY total_profit DESC) AS sales_rank 
    FROM 
        sales_summary
    JOIN 
        store ON sales_summary.ss_store_sk = store.s_store_sk
)
SELECT 
    s.s_store_name,
    s.total_profit,
    s.total_sales,
    CASE 
        WHEN s.sales_rank <= 5 THEN 'Top Performer'
        ELSE 'Average Performer'
    END AS performance_category,
    COALESCE(a.ca_city, 'Unknown') AS store_city,
    COALESCE(d.d_day_name, 'Unknown Day') AS sales_day,
    MAX(i.i_current_price) AS highest_item_price
FROM 
    high_performance_stores s
LEFT JOIN 
    customer_address a ON a.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = (SELECT ss_customer_sk FROM store_sales WHERE ss_store_sk = s.s_store_sk LIMIT 1))
LEFT JOIN 
    date_dim d ON d.d_date_sk = (SELECT ss_sold_date_sk FROM store_sales WHERE ss_store_sk = s.s_store_sk ORDER BY ss_sold_date_sk DESC LIMIT 1)
JOIN 
    item i ON i.i_item_sk = (SELECT ss_item_sk FROM store_sales WHERE ss_store_sk = s.s_store_sk ORDER BY ss_ticket_number DESC LIMIT 1)
GROUP BY 
    s.s_store_name, s.total_profit, s.total_sales, s.sales_rank, a.ca_city, d.d_day_name
ORDER BY 
    s.total_profit DESC;
