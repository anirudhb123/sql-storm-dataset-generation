
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 2459830 AND 2459870
),
ItemDetails AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        COALESCE(MAX(p.p_discount_active), 'N') AS discount_active
    FROM
        item i
    LEFT JOIN
        promotion p ON i.i_item_sk = p.p_item_sk
    GROUP BY
        i.i_item_id, i.i_product_name
)
SELECT
    ca.ca_city,
    ca.ca_state,
    SUM(rs.ws_ext_sales_price) AS total_sales,
    AVG(rs.ws_quantity) AS avg_quantity,
    COUNT(DISTINCT rs.ws_order_number) AS distinct_orders,
    id.i_product_name,
    id.discount_active
FROM
    RankedSales rs
JOIN
    customer c ON rs.ws_order_number = c.c_customer_id
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN
    ItemDetails id ON rs.ws_item_sk = id.i_item_id
WHERE
    ca.ca_country = 'USA'
    AND (c.c_birth_year >= 1980 OR c.c_birth_year IS NULL)
GROUP BY
    ca.ca_city, ca.ca_state, id.i_product_name, id.discount_active
HAVING
    SUM(rs.ws_ext_sales_price) > 1000
ORDER BY
    total_sales DESC
LIMIT 100;
