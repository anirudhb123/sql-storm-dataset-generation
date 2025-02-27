
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_sales_price * ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_sales_price * cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_sales_price * ss.ss_quantity), 0) AS total_store_sales
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
        LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
        LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
IncomeBreakdown AS (
    SELECT 
        h.hd_demo_sk,
        h.hd_income_band_sk,
        SUM(CASE 
            WHEN h.hd_buy_potential = 'High' THEN 1 
            ELSE 0 
        END) AS high_buyers,
        SUM(CASE 
            WHEN h.hd_buy_potential = 'Medium' THEN 1 
            ELSE 0 
        END) AS medium_buyers,
        SUM(CASE 
            WHEN h.hd_buy_potential = 'Low' THEN 1 
            ELSE 0 
        END) AS low_buyers
    FROM 
        household_demographics h
    GROUP BY 
        h.hd_demo_sk, h.hd_income_band_sk
),
RankedSales AS (
    SELECT 
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        RANK() OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) DESC) as sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    rs.c_first_name,
    rs.c_last_name,
    rs.total_web_sales,
    rs.total_catalog_sales,
    rs.total_store_sales,
    ib.high_buyers,
    ib.medium_buyers,
    ib.low_buyers
FROM 
    RankedSales rs
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_first_name = rs.c_first_name AND c.c_last_name = rs.c_last_name)
LEFT JOIN 
    IncomeBreakdown ib ON ib.hd_demo_sk = cd.cd_demo_sk
WHERE 
    rs.sales_rank <= 10
    AND rs.total_web_sales IS NOT NULL
    AND rs.total_catalog_sales IS NOT NULL
ORDER BY 
    rs.total_web_sales DESC, 
    rs.total_catalog_sales DESC, 
    rs.total_store_sales DESC;
