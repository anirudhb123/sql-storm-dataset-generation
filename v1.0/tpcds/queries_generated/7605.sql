
WITH SalesStats AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit,
        d.d_year
    FROM
        catalog_sales cs
    JOIN
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        cs.cs_item_sk, d.d_year
),
TopItems AS (
    SELECT
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_profit) AS total_profit
    FROM
        store_sales ss
    JOIN
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        ss.ss_item_sk
    ORDER BY
        total_profit DESC
    LIMIT 10
),
CombinedStats AS (
    SELECT
        si.i_item_id,
        COALESCE(s.total_quantity, 0) AS catalog_quantity,
        COALESCE(t.total_quantity, 0) AS store_quantity,
        COALESCE(s.total_profit, 0) AS catalog_profit,
        COALESCE(t.total_profit, 0) AS store_profit
    FROM
        item si
    LEFT JOIN SalesStats s ON si.i_item_sk = s.cs_item_sk
    LEFT JOIN TopItems t ON si.i_item_sk = t.ss_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    SUM(cs.ws_net_profit) AS total_web_profit,
    SUM(cs.ws_quantity) AS total_web_quantity
FROM 
    customer c
JOIN 
    web_sales cs ON c.c_customer_sk = cs.ws_bill_customer_sk
JOIN 
    CombinedStats stat ON cs.ws_item_sk = stat.i_item_id
WHERE 
    (stat.catalog_profit + stat.store_profit) > 1000
GROUP BY 
    c.c_first_name, 
    c.c_last_name
ORDER BY 
    total_web_profit DESC;
