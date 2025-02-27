
WITH SalesSummary AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_net_paid) AS total_net_paid,
        MAX(cs_sold_date_sk) AS last_sold_date
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
TopSellingItems AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_store_quantity_sold,
        SUM(ss.ss_net_paid) AS total_store_net_paid
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
    ORDER BY 
        total_store_quantity_sold DESC
    LIMIT 5
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    s.total_quantity_sold AS catalog_quantity_sold,
    s.total_net_paid AS catalog_net_paid,
    tsi.total_store_quantity_sold,
    tsi.total_store_net_paid
FROM 
    SalesSummary s
JOIN 
    CustomerDetails cd ON cd.c_customer_sk IN (
        SELECT DISTINCT cs_bill_customer_sk FROM catalog_sales WHERE cs_item_sk = s.cs_item_sk
    )
JOIN 
    TopSellingItems tsi ON s.cs_item_sk = tsi.ss_item_sk
WHERE 
    s.last_sold_date > (SELECT MAX(d_date) FROM date_dim WHERE d_current_year = 'Y')
ORDER BY 
    catalog_quantity_sold DESC;
