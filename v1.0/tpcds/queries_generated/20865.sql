
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS sales_count,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank,
        STRING_AGG(DISTINCT CONCAT(ws_bill_customer_sk, '|', ws_ship_cdemo_sk), '; ') AS customer_link
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 100 
        AND ws_quantity > 0 
    GROUP BY 
        ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'UNKNOWN'
            WHEN cd.cd_dep_count < 1 THEN 'NO_DEPENDENTS'
            ELSE 'WITH_DEPENDENTS' 
        END AS dep_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND c.c_birth_month IN (1, 5, 7, 12) 
),
SalesWithDemographics AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        rs.sales_count,
        cd.cd_gender,
        cd.dep_status 
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerDemographics cd ON cd.c_customer_sk = (SELECT TOP 1 c.c_customer_sk FROM customer c 
                                                       WHERE c.c_current_addr_sk = (SELECT MAX(c1.c_current_addr_sk) FROM customer c1) 
                                                       ORDER BY NEWID())
    WHERE 
        rs.sales_rank <= 5 
)
SELECT 
    swd.ws_item_sk,
    swd.total_sales,
    swd.sales_count,
    swd.cd_gender,
    swd.dep_status,
    DENSE_RANK() OVER (ORDER BY swd.total_sales DESC) AS dense_sales_rank
FROM 
    SalesWithDemographics swd
WHERE 
    COALESCE(swd.cd_gender, 'N/A') NOT IN ('F', 'M')
ORDER BY 
    swd.total_sales DESC;
