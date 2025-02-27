
SELECT
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    d.d_date AS purchase_date,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS purchased_items,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    c.cd_gender,
    c.cd_marital_status
FROM
    customer c
JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE
    d.d_year = 2023
    AND (c.cd_gender = 'F' OR c.cd_marital_status = 'M')
GROUP BY
    c.c_customer_id, full_name, purchase_date, c.cd_gender, c.cd_marital_status
ORDER BY
    total_spent DESC
LIMIT 100;
