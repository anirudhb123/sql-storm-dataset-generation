
WITH sales_summary AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN cs.cs_quantity ELSE 0 END) AS male_sales,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN cs.cs_quantity ELSE 0 END) AS female_sales
    FROM store_sales cs
    JOIN store s ON cs.ss_store_sk = s.s_store_sk
    JOIN customer c ON cs.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cs.ss_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY s.s_store_sk, s.s_store_name
), address_summary AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        SUM(ss.total_quantity_sold) AS total_quantity_by_city
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN sales_summary ss ON c.c_customer_sk = ss.s_store_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.total_customers,
    a.total_quantity_by_city,
    COALESCE(SUM(ss.total_net_profit), 0) AS total_profit_by_city
FROM address_summary a
LEFT JOIN sales_summary ss ON a.total_quantity_by_city = ss.total_quantity_sold
GROUP BY a.ca_city, a.ca_state, a.total_customers, a.total_quantity_by_city
ORDER BY a.total_quantity_by_city DESC;
