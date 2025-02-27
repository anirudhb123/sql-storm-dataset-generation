
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(cs.cs_quantity, 0)) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
FilteredSales AS (
    SELECT 
        c.c_customer_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cs.cs_net_profit DESC) as order_rank
    FROM 
        customer c
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_quantity,
    cs.order_count,
    cs.avg_net_profit,
    fs.cs_order_number,
    fs.cs_quantity,
    fs.cs_net_profit
FROM 
    CustomerStats cs
LEFT JOIN 
    FilteredSales fs ON cs.c_customer_sk = fs.c_customer_sk AND fs.order_rank <= 3
WHERE 
    cs.total_quantity > (SELECT AVG(total_quantity) FROM CustomerStats) 
    AND cs.order_count IS NOT NULL
ORDER BY 
    cs.avg_net_profit DESC NULLS LAST;

WITH RECURSIVE IncomeCategorization AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        0 AS level
    FROM 
        income_band ib
    UNION ALL
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ic.level + 1
    FROM 
        IncomeCategorization ic
    INNER JOIN 
        income_band ib ON ic.ib_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ib.ib_lower_bound < 100000
)
SELECT 
    DISTINCT cd.cd_marital_status,
    COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
    SUM(cs.total_quantity) AS quantity_sum
FROM 
    CustomerStats cs
JOIN 
    household_demographics hd ON cs.c_customer_sk = hd.hd_demo_sk
JOIN 
    IncomeCategorization ic ON hd.hd_income_band_sk = ic.ib_income_band_sk
WHERE 
    ic.level > 0
GROUP BY 
    cd.cd_marital_status
HAVING 
    SUM(cs.total_quantity) > (SELECT AVG(total_quantity) FROM CustomerStats)
ORDER BY 
    customer_count DESC;
