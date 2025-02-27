
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM
        web_sales
    GROUP BY
        ws_sold_date_sk,
        ws_item_sk

    UNION ALL

    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity),
        COUNT(cs_order_number),
        SUM(cs_net_profit)
    FROM
        catalog_sales
    GROUP BY
        cs_sold_date_sk,
        cs_item_sk
),
AddressInfo AS (
    SELECT
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM
        customer_address
    JOIN
        customer ON ca_address_sk = c_current_addr_sk
    GROUP BY
        ca_address_sk,
        ca_city,
        ca_state,
        ca_country
),
DailySales AS (
    SELECT
        d.d_date,
        SUM(s.total_quantity) AS daily_total_quantity,
        SUM(s.total_profit) AS daily_total_profit
    FROM
        Date_Dim d
    LEFT JOIN
        SalesCTE s ON d.d_date_sk = s.ws_sold_date_sk
    GROUP BY
        d.d_date
)

SELECT
    a.ca_city,
    a.ca_state,
    a.ca_country,
    d.daily_total_quantity,
    d.daily_total_profit,
    (SELECT COUNT(DISTINCT c.c_customer_sk)
     FROM customer c WHERE c.c_current_addr_sk = a.ca_address_sk) AS total_customers,
    (b.total_orders / NULLIF(b.total_quantity, 0)) AS avg_orders_per_item,
    b.total_profit AS total_item_profit
FROM
    AddressInfo a
LEFT JOIN
    (SELECT
        ws_item_sk,
        SUM(total_orders) AS total_orders,
        SUM(total_quantity) AS total_quantity,
        SUM(total_profit) AS total_profit
     FROM
        SalesCTE
     GROUP BY
        ws_item_sk) b ON a.customer_count > 0
JOIN
    DailySales d ON d.daily_total_quantity > 1000
WHERE
    a.ca_state IN ('CA', 'NY')
ORDER BY
    d.daily_total_profit DESC
LIMIT 50;
