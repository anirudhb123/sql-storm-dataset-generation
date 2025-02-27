
WITH RECURSIVE SalesHierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        SUM(ws.ws_net_paid) AS total_spent,
        1 AS hierarchy_level
    FROM
        customer c
    LEFT JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE
        ws.ws_sold_date_sk >= 1000
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city

    UNION ALL

    SELECT
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ca.ca_city,
        SUM(ws.ws_net_paid) AS total_spent,
        h.hierarchy_level + 1
    FROM
        SalesHierarchy h
    JOIN
        customer ch ON h.c_customer_sk = ch.c_current_cdemo_sk
    LEFT JOIN
        customer_address ca ON ch.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN
        web_sales ws ON ch.c_customer_sk = ws.ws_ship_customer_sk
    WHERE
        ws.ws_sold_date_sk >= 1000
    GROUP BY
        ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ca.ca_city, h.hierarchy_level
),
RankedSales AS (
    SELECT
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        SUM(ws.ws_net_paid) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_net_paid) DESC) AS city_rank
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        c.c_first_name, c.c_last_name, ca.ca_city
)
SELECT
    h.c_first_name,
    h.c_last_name,
    h.ca_city,
    h.total_spent,
    r.city_rank
FROM
    SalesHierarchy h
LEFT JOIN
    RankedSales r ON h.c_first_name = r.c_first_name AND h.c_last_name = r.c_last_name AND h.ca_city = r.ca_city
WHERE
    h.total_spent > 1000 OR r.city_rank <= 5
ORDER BY
    h.ca_city, h.total_spent DESC
FETCH FIRST 50 ROWS ONLY;
