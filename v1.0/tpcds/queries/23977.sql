
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        ARRAY_AGG(DISTINCT ca.ca_city) AS cities,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status_group
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_sk, c.c_email_address, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
SalesData AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_store_quantity,
        SUM(ss.ss_net_paid) AS total_store_net_paid,
        COUNT(DISTINCT ss.ss_store_sk) AS store_count
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
),
FinalReport AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_email_address,
        cs.cities,
        cs.marital_status_group,
        COALESCE(rs.total_quantity, 0) AS web_total_quantity,
        COALESCE(rs.total_net_paid, 0) AS web_total_net_paid,
        COALESCE(sd.total_store_quantity, 0) AS store_total_quantity,
        COALESCE(sd.total_store_net_paid, 0) AS store_total_net_paid,
        sd.store_count
    FROM 
        CustomerSummary cs
    LEFT JOIN 
        RankedSales rs ON rs.ws_item_sk = (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = cs.c_customer_sk LIMIT 1)
    LEFT JOIN 
        SalesData sd ON sd.ss_item_sk = (SELECT ss_item_sk FROM store_sales WHERE ss_customer_sk = cs.c_customer_sk LIMIT 1)
)
SELECT 
    fr.c_customer_sk,
    fr.c_email_address,
    fr.cities,
    fr.marital_status_group,
    fr.web_total_quantity,
    fr.web_total_net_paid,
    fr.store_total_quantity,
    fr.store_total_net_paid,
    fr.store_count,
    CASE 
        WHEN fr.web_total_quantity > fr.store_total_quantity THEN 'Web Dominant'
        WHEN fr.web_total_quantity < fr.store_total_quantity THEN 'Store Dominant'
        ELSE 'Equal Sales'
    END AS sales_comparison
FROM 
    FinalReport fr
WHERE 
    fr.cities IS NOT NULL
ORDER BY 
    fr.store_total_net_paid DESC, fr.web_total_net_paid DESC;
