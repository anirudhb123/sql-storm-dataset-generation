
WITH RankedSales AS (
    SELECT 
        cs_ship_mode_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY cs_ship_mode_sk ORDER BY SUM(cs_net_profit) DESC) AS profit_rank
    FROM
        catalog_sales
    WHERE
        cs_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2022 AND d_month_seq BETWEEN 1 AND 12
        )
    GROUP BY
        cs_ship_mode_sk
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit,
        CUME_DIST() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws_net_profit) DESC) AS gender_profit_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_month = 2 AND c.c_birth_day IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
StoreProfit AS (
    SELECT 
        s.s_store_sk,
        SUM(ss_net_profit) AS total_store_profit,
        COUNT(ss_ticket_number) AS total_sales_count
    FROM 
        store s
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    R.cs_ship_mode_sk,
    R.total_quantity,
    C.c_first_name,
    C.c_last_name,
    S.total_store_profit,
    CASE 
        WHEN C.gender_profit_rank < 0.5 THEN 'Above Average'
        ELSE 'Below Average'
    END AS customer_profit_rank,
    COALESCE(S.total_sales_count, 0) AS total_store_sales,
    (SELECT CONCAT('Shipping Method: ', sm_type) FROM ship_mode WHERE sm_ship_mode_sk = R.cs_ship_mode_sk) AS shipping_info
FROM 
    RankedSales R
JOIN 
    CustomerStatistics C ON R.cs_ship_mode_sk = (
        SELECT cs_ship_mode_sk 
        FROM catalog_sales 
        WHERE cs_ship_mode_sk IS NOT NULL 
        ORDER BY RANDOM() 
        LIMIT 1
    )
LEFT JOIN 
    StoreProfit S ON S.total_store_profit > 1000
WHERE 
    R.profit_rank <= 5 
ORDER BY 
    R.total_net_profit DESC, C.total_profit DESC
LIMIT 10;
