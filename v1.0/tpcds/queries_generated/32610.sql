
WITH RECURSIVE Income_Band AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk = 1
    UNION ALL
    SELECT b.ib_income_band_sk, b.ib_lower_bound, b.ib_upper_bound
    FROM income_band b
    JOIN Income_Band p ON b.ib_income_band_sk = p.ib_income_band_sk + 1
),
Customer_Orders AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales_price,
        COUNT(ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_purchased
    FROM customer c
    LEFT OUTER JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year IS NOT NULL
    GROUP BY c.c_customer_id
),
Top_Customers AS (
    SELECT 
        co.c_customer_id,
        co.total_sales_price,
        co.total_orders,
        co.last_purchase_date,
        CASE 
            WHEN co.total_sales_price > 1000 THEN 'High Value'
            WHEN co.total_sales_price BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM Customer_Orders co
    ORDER BY co.total_sales_price DESC
    LIMIT 10
)
SELECT 
    t.c_customer_id,
    t.total_sales_price,
    t.total_orders,
    t.last_purchase_date,
    t.customer_value,
    SUM(i.ib_lower_bound) AS total_income_band_lower,
    COUNT(DISTINCT ca.ca_address_sk) AS total_addresses
FROM Top_Customers t
LEFT JOIN customer_address ca ON t.c_customer_id = ca.ca_address_id
LEFT JOIN Income_Band i ON i.ib_lower_bound <= t.total_sales_price AND i.ib_upper_bound >= t.total_sales_price
GROUP BY t.c_customer_id, t.total_sales_price, t.total_orders, t.last_purchase_date, t.customer_value
HAVING COUNT(DISTINCT ca.ca_address_sk) > 2
ORDER BY total_sales_price DESC;
