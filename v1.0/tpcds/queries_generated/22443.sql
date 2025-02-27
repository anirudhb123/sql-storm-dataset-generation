
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk, ss_item_sk
),
HighProfitItems AS (
    SELECT 
        r.ss_store_sk, 
        r.ss_item_sk, 
        r.total_quantity,
        r.total_profit,
        (SELECT COUNT(*) FROM RankedSales WHERE ss_store_sk = r.ss_store_sk AND total_profit > r.total_profit) AS higher_profit_count
    FROM 
        RankedSales r
    WHERE 
        r.rank <= 5
),
CustomerProfits AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ss.net_profit) AS customer_total_profit
    FROM 
        customer c
    JOIN 
        store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year = 1980 AND (c.c_gender = 'M' OR c.c_gender IS NULL)
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    h.ss_store_sk,
    h.ss_item_sk,
    h.total_quantity,
    h.total_profit,
    h.higher_profit_count,
    cp.customer_total_profit,
    CASE WHEN h.total_profit IS NULL THEN 'N/A' ELSE 
         CASE WHEN h.higher_profit_count > 0 THEN 'Above Average' ELSE 'Top Performer' END END AS performance_category
FROM 
    HighProfitItems h
LEFT JOIN 
    CustomerProfits cp ON h.ss_item_sk = cp.c_customer_sk
ORDER BY 
    h.ss_store_sk, h.total_profit DESC;

WITH RECURSIVE AddressHierarchy AS (
    SELECT 
        ca_address_sk, 
        ca_city,
        ca_state,
        ca_country,
        0 AS level
    FROM 
        customer_address
    WHERE  
        ca_city IS NOT NULL
    UNION ALL
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ah.level + 1
    FROM 
        customer_address ca
    JOIN 
        AddressHierarchy ah ON ca.ca_address_sk = ah.ca_address_sk 
    WHERE 
        ca.ca_state = ah.ca_state
)
SELECT 
    SUM(CASE WHEN level = 0 THEN 1 ELSE 0 END) AS base_level_count,
    SUM(CASE WHEN level = 1 THEN 1 ELSE 0 END) AS first_level_count,
    COALESCE(MAX(level), -1) AS max_level_reached
FROM 
    AddressHierarchy
WHERE 
    ca_country = 'USA' AND (ca_state IS NOT NULL OR ca_state IS NULL)
HAVING 
    COUNT(DISTINCT ca_city) > 10;
