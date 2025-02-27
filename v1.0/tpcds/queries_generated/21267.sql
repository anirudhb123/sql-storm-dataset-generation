
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rank_sales,
        COALESCE(CAST(date_dim.d_date AS VARCHAR), 'Unknown Date') AS sale_date
    FROM 
        web_sales ws
    LEFT JOIN 
        date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
),
discounted_sales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity * (CASE WHEN rank_sales = 1 THEN 0.9 ELSE 1 END)) AS final_sales_price
    FROM 
        ranked_sales
    GROUP BY 
        ws_order_number, ws_item_sk
),
complex_conditions AS (
    SELECT 
        address.ca_city,
        COUNT(DISTINCT sales.ws_order_number) AS order_count,
        SUM(sales.final_sales_price) AS total_sales,
        AVG(CASE WHEN sales.total_sales > 100 THEN sales.final_sales_price ELSE NULL END) AS avg_discounted_sales
    FROM 
        customer_address address
    JOIN 
        customer c ON address.ca_address_sk = c.c_current_addr_sk
    JOIN 
        discounted_sales sales ON sales.ws_order_number IN (SELECT DISTINCT ws_order_number FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
    WHERE 
        address.ca_state IS NOT NULL
        AND address.ca_city NOT LIKE '%City%'
        AND address.ca_country IN ('USA', 'Canada')
    GROUP BY 
        address.ca_city
)
SELECT 
    ca_city,
    order_count,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales Data'
        ELSE CAST(total_sales AS VARCHAR)
    END AS total_sales_display,
    COALESCE(avg_discounted_sales, 0) AS avg_discounted_sales
FROM 
    complex_conditions
WHERE 
    order_count > 5
ORDER BY 
    avg_discounted_sales DESC, ca_city
LIMIT 10;
