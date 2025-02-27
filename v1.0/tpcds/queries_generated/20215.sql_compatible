
WITH RankedSales AS (
    SELECT 
        s.ss_store_sk,
        s.ss_item_sk,
        s.ss_sales_price,
        DENSE_RANK() OVER (PARTITION BY s.ss_store_sk ORDER BY s.ss_net_profit DESC) AS ProfitRank,
        COALESCE(s2.total_return_quantity, 0) AS total_return_quantity
    FROM 
        store_sales s
    LEFT JOIN (
        SELECT 
            sr_store_sk,
            sr_item_sk,
            SUM(sr_return_quantity) AS total_return_quantity
        FROM 
            store_returns
        GROUP BY 
            sr_store_sk, 
            sr_item_sk
    ) s2 ON s.ss_store_sk = s2.sr_store_sk AND s.ss_item_sk = s2.sr_item_sk
    WHERE 
        s.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                               AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TopProfitableItems AS (
    SELECT 
        rs.ss_store_sk,
        rs.ss_item_sk,
        rs.ss_sales_price,
        rs.ProfitRank,
        CASE 
            WHEN rs.total_return_quantity > 0 THEN 'Returned'
            ELSE 'Sold'
        END AS SaleStatus
    FROM 
        RankedSales rs
    WHERE 
        rs.ProfitRank <= 3
    ORDER BY 
        rs.ss_store_sk, 
        rs.ProfitRank
),
SalesWithDemographics AS (
    SELECT 
        tpi.ss_store_sk,
        tpi.ss_item_sk,
        tpi.ss_sales_price,
        tpi.SaleStatus,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_buy_potential,
        hd.hd_income_band_sk
    FROM 
        TopProfitableItems tpi
    LEFT JOIN customer c ON tpi.ss_store_sk = c.c_customer_sk 
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    swd.ss_store_sk,
    swd.ss_item_sk,
    SUM(swd.ss_sales_price) AS total_sales_price,
    STRING_AGG(DISTINCT swd.SaleStatus) AS sale_statuses,
    COUNT(DISTINCT swd.hd_income_band_sk) AS distinct_income_bands,
    AVG(CASE WHEN swd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_perc,
    COUNT(CASE WHEN swd.hd_buy_potential IS NULL THEN 1 END) AS null_buy_potential
FROM 
    SalesWithDemographics swd
GROUP BY 
    swd.ss_store_sk, 
    swd.ss_item_sk
HAVING 
    COUNT(swd.ss_item_sk) > 1 
    AND AVG(swd.ss_sales_price) > (
        SELECT AVG(ws_sales_price) FROM web_sales
    )
ORDER BY 
    total_sales_price DESC;
