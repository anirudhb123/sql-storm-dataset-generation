
WITH AddressPrefixes AS (
    SELECT 
        ca_address_sk,
        UPPER(SUBSTRING(ca_street_name, 1, 3)) AS street_prefix,
        ca_city,
        ca_state
    FROM customer_address
),
GenderCount AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count
    FROM customer_demographics
    GROUP BY cd_gender
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_item_sk
),
RankedSales AS (
    SELECT 
        ws_item_sk,
        total_sales,
        total_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM SalesData
),
CombinedData AS (
    SELECT 
        a.street_prefix,
        a.ca_city,
        a.ca_state,
        g.cd_gender,
        s.total_sales,
        s.total_orders,
        r.sales_rank
    FROM AddressPrefixes a
    CROSS JOIN GenderCount g
    JOIN RankedSales s ON s.ws_item_sk = (SELECT MIN(ws_item_sk) FROM RankedSales)
)
SELECT 
    street_prefix,
    ca_city,
    ca_state,
    cd_gender,
    total_sales,
    total_orders,
    sales_rank
FROM CombinedData
WHERE total_sales > 1000
ORDER BY sales_rank, ca_city;
