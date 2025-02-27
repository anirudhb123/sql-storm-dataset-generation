
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales,
        ws_net_profit AS profit,
        DATEADD(DAY, -1, d_date) AS date_range
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    WHERE 
        d_date >= '2023-01-01' AND d_date < '2024-01-01'
    GROUP BY 
        ws_item_sk, ws_net_profit

    UNION ALL

    SELECT 
        ws_item_sk, 
        total_sales + SUM(ws_quantity) AS total_sales, 
        profit,
        DATEADD(DAY, -1, date_range) AS date_range
    FROM 
        SalesCTE
    JOIN 
        web_sales ON SalesCTE.ws_item_sk = web_sales.ws_item_sk
    JOIN 
        date_dim ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    WHERE 
        date_range < '2023-01-01'
    GROUP BY 
        ws_item_sk, profit
),

Profitability AS (
    SELECT 
        SS.ss_item_sk,
        I.i_item_desc,
        S.s_store_id,
        SUM(SS.ss_net_profit) AS total_net_profit,
        COUNT(SS.ss_ticket_number) AS total_transactions
    FROM 
        store_sales SS
    JOIN 
        item I ON SS.ss_item_sk = I.i_item_sk
    JOIN 
        store S ON SS.ss_store_sk = S.s_store_sk
    GROUP BY 
        SS.ss_item_sk, I.i_item_desc, S.s_store_id
)

SELECT 
    C.c_customer_id,
    CA.ca_city,
    CASE 
        WHEN CD.cd_gender = 'M' THEN 'Mr. ' + C.c_first_name 
        ELSE 'Ms. ' + C.c_first_name 
    END AS customer_name,
    SUM(SP.total_sales) AS total_web_sales,
    COALESCE(SP.profit, 0) AS total_profit,
    SUM(P.total_net_profit) AS store_net_profit,
    COUNT(DISTINCT WP.wp_web_page_sk) AS total_web_visits
FROM 
    customer C
LEFT JOIN 
    customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
LEFT JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
LEFT JOIN 
    SalesCTE SP ON C.c_customer_sk = SP.ws_item_sk
LEFT JOIN 
    Profitability P ON C.c_customer_sk = P.ss_item_sk
LEFT JOIN 
    web_page WP ON C.c_customer_sk = WP.wp_customer_sk
WHERE 
    C.c_birth_year > 1980
    AND (P.total_net_profit IS NULL OR P.total_net_profit > 1000)
GROUP BY 
    C.c_customer_id, CA.ca_city, customer_name
HAVING 
    total_web_sales > 100
ORDER BY 
    total_web_sales DESC
LIMIT 50;
