
WITH customer_activity AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(ws.ws_quantity) AS total_web_sales,
        SUM(cs.cs_quantity) AS total_catalog_sales,
        COUNT(DISTINCT sr.ticket_number) AS total_store_returns,
        COUNT(DISTINCT wr.order_number) AS total_web_returns
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk OR cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
)
SELECT 
    ca.ca_state,
    SUM(ca.total_web_sales) AS total_web_sales,
    SUM(ca.total_catalog_sales) AS total_catalog_sales,
    SUM(ca.total_store_returns) AS total_store_returns,
    SUM(ca.total_web_returns) AS total_web_returns
FROM
    customer_activity ca
JOIN
    customer_address ca ON ca.c_customer_sk = ca.ca_address_sk
GROUP BY
    ca.ca_state
ORDER BY
    total_web_sales DESC, total_catalog_sales DESC;
