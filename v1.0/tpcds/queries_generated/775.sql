
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopSales AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_net_paid,
        i.i_item_desc,
        c.c_country
    FROM 
        RankedSales AS r
    JOIN 
        item AS i ON r.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        customer AS c ON c.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = r.ws_item_sk)
    WHERE 
        r.rank_sales <= 5
),
StoresWithSales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_profit) AS total_profit
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
)
SELECT 
    t.ws_item_sk,
    t.i_item_desc,
    t.total_quantity,
    t.total_net_paid,
    s.ss_store_sk,
    s.total_profit
FROM 
    TopSales AS t
JOIN 
    StoresWithSales AS s ON s.ss_store_sk = (SELECT s_store_sk FROM store WHERE s_city = 'San Francisco' LIMIT 1)
UNION ALL
SELECT 
    t.ws_item_sk,
    t.i_item_desc,
    t.total_quantity,
    t.total_net_paid,
    NULL AS ss_store_sk,
    NULL AS total_profit
FROM 
    TopSales AS t
WHERE 
    t.ws_item_sk IS NULL;
