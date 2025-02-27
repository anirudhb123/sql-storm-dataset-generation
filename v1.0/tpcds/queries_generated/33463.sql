
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        1 AS Level
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F'
    UNION ALL
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        Level + 1
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer c ON ch.c_customer_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
),
DateFilteredSales AS (
    SELECT 
        w.ws_order_number,
        SUM(w.ws_net_profit) AS TotalProfit
    FROM 
        web_sales w
    JOIN 
        date_dim d ON w.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        w.ws_order_number
),
TopStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_paid) AS TotalSales
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        s.s_store_sk, s.s_store_name
    ORDER BY 
        TotalSales DESC
    LIMIT 10
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ch.cd_gender,
    ch.cd_marital_status,
    ch.cd_purchase_estimate,
    dfs.TotalProfit,
    ts.TotalSales
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    DateFilteredSales dfs ON ch.c_customer_sk = dfs.ws_order_number
LEFT JOIN 
    TopStores ts ON ts.s_store_sk = ch.c_customer_sk
WHERE 
    ch.Level >= 2
ORDER BY 
    ch.cd_purchase_estimate DESC, 
    ts.TotalSales DESC
LIMIT 100;
