
WITH RECURSIVE sales_cte AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        1 AS level
    FROM
        web_sales
    WHERE
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)

    UNION ALL

    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity + prev.ws_quantity,
        ws_sales_price,
        ws_ext_sales_price + prev.ws_ext_sales_price,
        level + 1
    FROM
        web_sales ws
    JOIN sales_cte prev ON ws_item_sk = prev.ws_item_sk
    WHERE
        ws_sold_date_sk = prev.ws_sold_date_sk - 1
        AND level < 5
)

SELECT
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS city_rank
FROM
    customer c
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN
    sales_cte s ON s.ws_item_sk = ws.ws_item_sk
WHERE
    ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    AND ca.ca_state = 'CA'
GROUP BY
    c.c_customer_id,
    ca.ca_city
HAVING
    SUM(ws.ws_ext_sales_price) > 1000 AND COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY
    total_sales DESC;
