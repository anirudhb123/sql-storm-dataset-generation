
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
CustomerIncome AS (
    SELECT 
        cd_demo_sk,
        SUM(CASE WHEN hd_income_band_sk IS NOT NULL THEN 1 ELSE 0 END) AS income_count,
        AVG(hd_dep_count) AS avg_dependents
    FROM customer_demographics
    LEFT JOIN household_demographics ON cd_demo_sk = hd_demo_sk
    GROUP BY cd_demo_sk
),
CostAnalysis AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        COALESCE(SUM(ws_net_profit), 0) AS total_net_profit,
        COALESCE(SUM(ss_net_profit), 0) AS store_net_profit
    FROM 
        inventory inv
    LEFT JOIN web_sales ws ON inv.inv_item_sk = ws.ws_item_sk
    LEFT JOIN store_sales ss ON inv.inv_item_sk = ss.ss_item_sk
    GROUP BY inv.inv_item_sk, inv.inv_quantity_on_hand
)
SELECT 
    ca.ca_address_id,
    c.c_first_name,
    c.c_last_name,
    sm.sm_type,
    TotalSales.TotalSold,
    TotalSales.TotalNetProfit,
    ci.income_count,
    ci.avg_dependents,
    CASE 
        WHEN ci.income_count > 10 THEN 'High Income'
        ELSE 'Low Income' 
    END AS Income_Category
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (
        SELECT 
            ws_ship_mode_sk 
        FROM 
            web_sales 
        WHERE 
            ws_bill_customer_sk = c.c_customer_sk
        ORDER BY 
            ws_sold_date_sk DESC 
        LIMIT 1
    )
LEFT JOIN 
    (SELECT 
        ws_bill_customer_sk, 
        SUM(ws_quantity) AS TotalSold, 
        SUM(ws_net_profit) AS TotalNetProfit 
     FROM 
        web_sales 
     GROUP BY 
        ws_bill_customer_sk) AS TotalSales ON TotalSales.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    CustomerIncome ci ON ci.cd_demo_sk = c.c_current_cdemo_sk
WHERE 
    (
        ca.ca_city = 'San Francisco' 
        AND (c.c_birth_year < 1980 OR ci.avg_dependents > 2)
    )
ORDER BY 
    TotalSales.TotalNetProfit DESC
LIMIT 100;
