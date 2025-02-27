
WITH CustomerCityCounts AS (
    SELECT
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM
        customer_address ca
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE
        ca_city IS NOT NULL
    GROUP BY
        ca_city
),
ItemSalesDetails AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_value
    FROM
        item i
    JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        i.i_item_id, i.i_item_desc
),
AddressWithSales AS (
    SELECT
        ca.ca_city,
        ci.customer_count,
        id.i_item_desc,
        id.total_quantity_sold,
        id.total_sales_value
    FROM
        CustomerCityCounts ci
    LEFT JOIN
        (SELECT DISTINCT ca.ca_city, ws.ws_order_number FROM customer_address ca JOIN web_sales ws ON ca.ca_address_sk = ws.ws_ship_addr_sk) sales_location ON ci.ca_city = sales_location.ca_city
    JOIN
        ItemSalesDetails id ON sales_location.ws_order_number IS NOT NULL
)
SELECT
    city,
    customer_count,
    total_quantity_sold,
    total_sales_value,
    CONCAT('City: ', city, ' has ', customer_count, ' customers and sold ', total_quantity_sold, ' items worth $', ROUND(total_sales_value, 2)) AS report
FROM
    AddressWithSales
ORDER BY
    total_sales_value DESC;
