
WITH RECURSIVE MonthlySales AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        date_dim d
    JOIN
        web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year, d.d_month_seq
    
    UNION ALL

    SELECT
        ms.year,
        ms.month + 1 AS month,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        MonthlySales ms
    JOIN
        web_sales ws ON ws.ws_sold_date_sk = (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = ms.year AND d.d_month_seq = ms.month + 1)
    WHERE
        (ms.year < (SELECT MAX(d.d_year) FROM date_dim d))
    GROUP BY
        ms.year, ms.month
),

SalesData AS (
    SELECT
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ws.ws_net_profit) AS total_sales
    FROM
        customer_address ca
    JOIN
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        ca.ca_city
),

AggSales AS (
    SELECT
        ca.ca_city,
        SUM(ws.ws_net_profit) AS city_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM
        customer_address ca
    JOIN
        web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY
        ca.ca_city
)

SELECT
    ms.year,
    ms.month,
    sd.ca_city,
    sd.customer_count,
    sd.total_sales,
    COALESCE(as.city_sales, 0) AS ranked_sales,
    RANK() OVER (PARTITION BY ms.year ORDER BY COALESCE(as.city_sales, 0) DESC) AS city_rank
FROM
    MonthlySales ms
JOIN
    SalesData sd ON 1=1
LEFT JOIN
    AggSales as ON sd.ca_city = as.ca_city
WHERE
    ms.total_net_profit > 1000
ORDER BY
    ms.year, ms.month, city_rank;
