
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sales_price DESC) AS sales_rank,
        c.c_last_name,
        c.c_first_name,
        ca.ca_city
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451772 AND 2451792
),
HighValueSales AS (
    SELECT 
        web_site_sk,
        ws_order_number,
        sales_price,
        c_last_name,
        c_first_name,
        ca_city
    FROM RankedSales
    WHERE sales_rank = 1
),
AggregateSales AS (
    SELECT 
        h.web_site_sk,
        COUNT(*) AS total_orders,
        SUM(h.sales_price) AS total_sales
    FROM HighValueSales h
    GROUP BY h.web_site_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    ads.web_site_sk,
    ads.total_orders,
    ads.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    CONCAT('Total sales for ', COALESCE(cd.ib_lower_bound::text, 'Unknown'), ' - ', COALESCE(cd.ib_upper_bound::text, 'Unknown')) AS income_band,
    ca.ca_city
FROM AggregateSales ads
JOIN CustomerDemographics cd ON ads.web_site_sk = cd.cd_demo_sk
JOIN customer_address ca ON ca.ca_address_id = (SELECT ca.ca_address_id FROM customer_address ca WHERE ca.ca_address_sk = cd.cd_demo_sk LIMIT 1)
WHERE cd.cd_marital_status = 'M' OR cd.cd_gender IS NULL
ORDER BY ads.total_sales DESC
LIMIT 10;
