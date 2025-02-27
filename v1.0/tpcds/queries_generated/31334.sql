
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.ss_sold_date_sk,
        cs.ss_item_sk,
        cs.ss_quantity,
        cs.ss_net_paid
    FROM 
        customer c
    JOIN 
        store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    WHERE 
        cs.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.ss_sold_date_sk,
        cs.ss_item_sk,
        cs.ss_quantity,
        cs.ss_net_paid
    FROM 
        customer c
    JOIN 
        store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    JOIN 
        SalesHierarchy sh ON cs.ss_item_sk = sh.ss_item_sk
    WHERE 
        sh.ss_sold_date_sk > cs.ss_sold_date_sk
),
ItemSummary AS (
    SELECT 
        sh.ss_item_sk,
        SUM(sh.ss_quantity) AS total_quantity,
        SUM(sh.ss_net_paid) AS total_sales
    FROM 
        SalesHierarchy sh
    GROUP BY 
        sh.ss_item_sk
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        hd_demo_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
IncomeBand AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound
    FROM 
        income_band
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT sh.c_customer_sk) AS customer_count,
    SUM(is.total_quantity) AS total_quantity,
    SUM(is.total_sales) AS total_sales
FROM 
    ItemSummary is
JOIN 
    Demographics d ON is.ss_item_sk IN (SELECT cs_item_sk FROM store_sales)
LEFT JOIN 
    IncomeBand ib ON d.cd_income_band_sk = ib.ib_income_band_sk
GROUP BY 
    d.cd_gender,
    d.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
HAVING 
    total_sales > 1000
ORDER BY 
    total_sales DESC;
