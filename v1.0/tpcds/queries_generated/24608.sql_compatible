
WITH RankedSales AS (
    SELECT 
        ws_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_customer_sk, ws_item_sk
),
FilteredSales AS (
    SELECT 
        ws.ws_customer_sk,
        ws.ws_item_sk,
        ws.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_state,
        COALESCE(ib.ib_income_band_sk, -1) AS income_band
    FROM 
        RankedSales ws
    JOIN 
        customer c ON c.c_customer_sk = ws.ws_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        ws.total_sales > (SELECT AVG(total_sales) FROM RankedSales) AND
        (cd.cd_marital_status IS NOT NULL OR ca.ca_state IS NULL)
),
SalesSummary AS (
    SELECT 
        fs.income_band,
        COUNT(DISTINCT fs.ws_customer_sk) AS customer_count,
        AVG(fs.total_sales) AS avg_sales,
        MIN(fs.total_sales) AS min_sales,
        MAX(fs.total_sales) AS max_sales
    FROM 
        FilteredSales fs
    GROUP BY 
        fs.income_band
)
SELECT 
    COALESCE(ss.income_band, 'No Income Band') AS income_band,
    ss.customer_count,
    ss.avg_sales,
    ss.min_sales,
    ss.max_sales
FROM 
    SalesSummary ss
FULL OUTER JOIN 
    (SELECT DISTINCT ib.ib_income_band_sk FROM income_band ib) AS ib ON ss.income_band = ib.ib_income_band_sk
ORDER BY 
    COALESCE(ss.income_band, 'No Income Band'),
    ss.avg_sales DESC;
