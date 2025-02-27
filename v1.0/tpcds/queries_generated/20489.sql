
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        COUNT(*) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                               (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk, ss_item_sk
),
HighProfit AS (
    SELECT 
        rs.ss_store_sk,
        rs.ss_item_sk,
        rs.total_sales,
        rs.total_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        RankedSales rs
    JOIN 
        date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    WHERE 
        rs.profit_rank <= 5
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS hd_buy_potential
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
),
SalesWithCity AS (
    SELECT 
        hs.ss_store_sk, 
        hs.total_profit, 
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY hs.total_profit DESC) AS city_rank
    FROM 
        HighProfit hs
    JOIN 
        store s ON s.s_store_sk = hs.ss_store_sk
    JOIN 
        customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = hs.ss_store_sk)
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    s.ca_city,
    s.total_profit,
    CASE 
        WHEN s.city_rank = 1 THEN 'TOP PROFIT'
        ELSE 'OTHER'
    END AS profit_status
FROM 
    CustomerDetails c
JOIN 
    SalesWithCity s ON c.c_customer_sk = s.ss_store_sk
WHERE 
    c.cd_gender = 'F' 
    AND (s.total_profit IS NOT NULL OR c.cd_marital_status IS NULL)
ORDER BY 
    s.total_profit DESC;
