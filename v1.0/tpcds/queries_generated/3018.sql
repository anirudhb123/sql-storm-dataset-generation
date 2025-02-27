
WITH SalesData AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year > 1980
    GROUP BY ws.web_site_sk, ws.web_name
),
SalesRanked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData
),
TopWebSites AS (
    SELECT 
        *
    FROM SalesRanked
    WHERE sales_rank <= 10
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.total_sales) AS total_sales_by_demographics
    FROM TopWebSites sd
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = sd.web_site_sk)
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(cd.total_sales_by_demographics, 0) AS total_sales_by_demographics,
    ABS(MAX(cd.total_sales_by_demographics) - MIN(cd.total_sales_by_demographics)) AS sales_difference
FROM CustomerDemographics cd
GROUP BY cd.cd_gender, cd.cd_marital_status
HAVING sales_difference > 5000
ORDER BY sales_difference DESC;
