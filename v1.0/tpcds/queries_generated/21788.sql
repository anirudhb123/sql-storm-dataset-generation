
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighSpender AS (
    SELECT 
        c.c_customer_id,
        (total_web_sales + total_catalog_sales + total_store_sales) AS total_sales
    FROM 
        CustomerSales c
    WHERE 
        (total_web_sales + total_catalog_sales + total_store_sales) > (
            SELECT 
                AVG(total_web_sales + total_catalog_sales + total_store_sales) 
            FROM 
                CustomerSales
        )
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count
    FROM 
        HighSpender hs
    JOIN customer_demographics cd 
        ON hs.c_customer_id = cd.cd_demo_sk
    JOIN CustomerSales cs 
        ON hs.c_customer_id = cs.c_customer_id
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    customer_count,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY customer_count DESC) AS rank_within_gender
FROM 
    CustomerDemographics cd
WHERE 
    customer_count > (SELECT AVG(customer_count) FROM CustomerDemographics)
ORDER BY 
    cd.cd_gender, rank_within_gender;
