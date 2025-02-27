
WITH RECURSIVE sales_data AS (
    SELECT 
        ss_sold_date_sk, 
        ss_item_sk, 
        SUM(ss_net_paid) AS total_net_sales,
        COUNT(ss_ticket_number) AS total_transactions
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_item_sk
    UNION ALL
    SELECT 
        sd.ss_sold_date_sk, 
        sd.ss_item_sk, 
        sd.total_net_sales + COALESCE(sub.total_net_sales, 0), 
        sd.total_transactions + COALESCE(sub.total_transactions, 0)
    FROM sales_data sd
    LEFT JOIN (
        SELECT ss_sold_date_sk, ss_item_sk, SUM(ss_net_paid) AS total_net_sales, COUNT(ss_ticket_number) AS total_transactions 
        FROM store_sales 
        WHERE ss_sold_date_sk < (
            SELECT MAX(ss_sold_date_sk) FROM store_sales
        )
        GROUP BY ss_sold_date_sk, ss_item_sk
    ) sub ON sd.ss_item_sk = sub.ss_item_sk
    WHERE sd.total_net_sales < 1000000
)

SELECT 
    ca.ca_city, 
    SUM(sd.total_net_sales) AS city_total_sales,
    COUNT(DISTINCT sd.ss_item_sk) AS unique_items_sold,
    AVG(sd.total_net_sales) OVER (PARTITION BY ca.ca_city) AS avg_sales_per_city,
    COALESCE(MAX(sd.total_transactions), 0) AS max_transactions,
    COUNT(DISTINCT sd.ss_sold_date_sk) AS days_active
FROM sales_data sd
JOIN customer_address ca ON ca.ca_address_sk = (
    SELECT c.c_current_addr_sk
    FROM customer c
    WHERE c.c_customer_sk = sd.ss_customer_sk
)
GROUP BY ca.ca_city
HAVING city_total_sales > 10000
ORDER BY city_total_sales DESC
LIMIT 10;
