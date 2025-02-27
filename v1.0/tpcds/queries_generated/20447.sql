
WITH RecursiveSales AS (
    SELECT 
        ws.bill_customer_sk, 
        ws.bill_addr_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS customer_ranking
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 100 
    GROUP BY 
        ws.bill_customer_sk, 
        ws.bill_addr_sk
),
FilteredDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE
            WHEN cd.cd_income_band_sk IS NULL THEN 'Unknown'
            ELSE ib.ib_income_band_sk::varchar
        END AS income_band,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        customer_address ca ON cd.cd_demo_sk = ca.ca_address_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, ib.ib_income_band_sk
),
AggregatedData AS (
    SELECT 
        fd.gender, 
        SUM(fs.total_sales) AS aggregated_sales,
        COUNT(fd.address_count) AS total_addresses
    FROM 
        FilteredDemographics fd
    JOIN 
        RecursiveSales fs ON fd.cd_demo_sk = fs.bill_customer_sk
    GROUP BY 
        fd.gender
),
FinalResult AS (
    SELECT 
        ag.*, 
        CASE 
            WHEN ag.aggregated_sales IS NULL THEN 0
            ELSE ag.aggregated_sales / NULLIF(total_addresses, 0)
        END AS avg_sales_per_address,
        RANK() OVER (ORDER BY aggregated_sales DESC) AS sales_rank
    FROM 
        AggregatedData ag
)
SELECT 
    fr.gender,
    fr.aggregated_sales,
    fr.avg_sales_per_address,
    COALESCE(fr.sales_rank, 'No Rank') AS sales_rank
FROM 
    FinalResult fr
WHERE 
    fr.aggregated_sales > 1000
ORDER BY 
    fr.aggregated_sales DESC
FETCH FIRST 10 ROWS ONLY;
