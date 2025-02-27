
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) as profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= CAST('2023-01-01' AS DATE) -- Sales in 2023
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        addr.ca_city,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year DESC) as cust_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address addr ON c.c_current_addr_sk = addr.ca_address_sk
    WHERE cd.cd_purchase_estimate > 1000
),
filtered_sales AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_sales_price) AS total_sales
    FROM web_sales s
    JOIN customer_info ci ON s.ws_bill_customer_sk = ci.c_customer_id
    GROUP BY s.ws_item_sk
),
total_sales AS (
    SELECT 
        f.ws_item_sk,
        f.total_quantity,
        f.total_sales,
        COALESCE(si.avg_price, 0) AS avg_price,
        CASE 
            WHEN f.total_sales > 10000 THEN 'High'
            WHEN f.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM filtered_sales f
    LEFT JOIN (
        SELECT 
            ws_item_sk,
            AVG(ws_sales_price) AS avg_price
        FROM web_sales
        GROUP BY ws_item_sk
    ) si ON f.ws_item_sk = si.ws_item_sk
),
top_sales AS (
    SELECT 
        t.ws_item_sk,
        t.total_quantity,
        t.total_sales,
        t.avg_price,
        t.sales_category,
        ROW_NUMBER() OVER (ORDER BY t.total_sales DESC) as sales_rank
    FROM total_sales t
)
SELECT 
    t.ws_item_sk,
    t.total_quantity,
    t.total_sales,
    t.avg_price,
    t.sales_category,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.ca_city
FROM top_sales t
JOIN customer_info ci ON t.ws_item_sk = ci.c_customer_id -- Ceramic filter
WHERE t.sales_rank <= 10
OR ci.cd_gender IN ('F') 
   AND ci.cd_marital_status IN ('S', 'M') 
ORDER BY t.total_sales DESC;
