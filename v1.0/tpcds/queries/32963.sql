
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_current_cdemo_sk,
        c_current_addr_sk,
        1 AS level
    FROM 
        customer
    WHERE 
        c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        c.c_current_addr_sk,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
AggregatedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        a.ws_item_sk,
        i.i_item_desc,
        a.total_quantity,
        a.total_profit,
        RANK() OVER (ORDER BY a.total_quantity DESC) AS rank
    FROM 
        AggregatedSales a
    JOIN 
        item i ON a.ws_item_sk = i.i_item_sk
    WHERE 
        a.total_quantity > 100
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    tsi.i_item_desc,
    tsi.total_quantity,
    tsi.total_profit,
    (SELECT 
         COUNT(*)
     FROM 
         store_sales ss
     WHERE 
         ss.ss_item_sk = tsi.ws_item_sk
         AND ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)) AS store_sales_count,
    CASE 
        WHEN ch.level = 1 THEN 'New Customer'
        ELSE 'Returning Customer'
    END AS customer_status
FROM 
    CustomerHierarchy ch
JOIN 
    TopSellingItems tsi ON ch.c_current_cdemo_sk = tsi.ws_item_sk
WHERE 
    ch.c_customer_sk IS NOT NULL
ORDER BY 
    tsi.total_quantity DESC, 
    ch.c_last_name, 
    ch.c_first_name;
