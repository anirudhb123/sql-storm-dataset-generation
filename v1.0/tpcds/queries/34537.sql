
WITH RECURSIVE Sales_Tiers AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS tier
    FROM store_sales
    GROUP BY ss_store_sk
    UNION ALL
    SELECT 
        ss_store_sk,
        total_sales * 0.95,
        transaction_count + 1,
        tier + 1
    FROM Sales_Tiers 
    WHERE tier < 10
),
Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year > 1980
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
Item_Stats AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        AVG(ws.ws_ext_sales_price) AS avg_sales_price,
        COUNT(ws.ws_order_number) AS num_orders,
        MAX(ws.ws_ext_sales_price) AS max_price,
        MIN(ws.ws_ext_sales_price) AS min_price
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
)
SELECT 
    ca.ca_city,
    SUM(css.total_web_sales) AS total_web_sales_by_city,
    AVG(iss.avg_sales_price) AS average_item_sales_price,
    COUNT(DISTINCT css.c_customer_sk) AS unique_customers,
    AVG(st.total_sales) AS average_store_sales
FROM customer_address ca
LEFT JOIN Customer_Sales css ON ca.ca_address_sk = css.c_customer_sk
LEFT JOIN Item_Stats iss ON css.sales_rank <= 10
LEFT JOIN Sales_Tiers st ON ca.ca_address_sk = st.ss_store_sk
WHERE ca.ca_state = 'CA'
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT css.c_customer_sk) > 5
ORDER BY total_web_sales_by_city DESC
LIMIT 10;
