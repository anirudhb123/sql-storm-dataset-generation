
WITH sales_data AS (
    SELECT 
        ss.s_store_sk, 
        ss.ss_sold_date_sk, 
        SUM(ss.ss_quantity) AS total_quantity_sold, 
        SUM(ss.ss_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ss.s_store_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS rank_profit
    FROM store_sales ss
    GROUP BY ss.s_store_sk, ss.ss_sold_date_sk
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk, 
        COUNT(DISTINCT s.s_store_sk) AS store_count,
        SUM(s.s_number_employees) AS total_employees
    FROM warehouse w 
    LEFT JOIN store s ON s.s_store_sk = w.w_warehouse_sk
    GROUP BY w.w_warehouse_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(a.ca_city, 'Unknown') AS city,
    COALESCE(a.ca_state, 'Unknown') AS state,
    CASE 
        WHEN SUM(sd.total_net_profit) IS NULL THEN 0 
        ELSE SUM(sd.total_net_profit) 
    END AS total_profit,
    CASE 
        WHEN wd.store_count IS NULL THEN 'No Stores' 
        ELSE 'Stores Present' 
    END AS store_status
FROM customer c
LEFT JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN sales_data sd ON c.c_customer_sk = sd.ss_customer_sk
LEFT JOIN warehouse_summary wd ON wd.w_warehouse_sk = a.ca_address_sk
WHERE c.c_birth_month IN (SELECT DISTINCT d.d_moy FROM date_dim d WHERE d.d_year = 2023 AND d.d_holiday = 'Y')
  AND (c.c_login IS NOT NULL OR c.c_email_address IS NOT NULL)
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state, wd.store_count
HAVING COUNT(sd.total_quantity_sold) > 5 
   OR (COUNT(sd.total_quantity_sold) = 0 AND SUM(sd.total_net_profit) < 0)
ORDER BY total_profit DESC, c.c_last_name ASC
LIMIT 100;
