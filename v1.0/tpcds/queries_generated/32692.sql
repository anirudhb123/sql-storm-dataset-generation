
WITH RECURSIVE TopCategories AS (
    SELECT i_category_id, i_category, i_item_sk
    FROM item
    WHERE i_category IS NOT NULL
    UNION ALL
    SELECT it.i_category_id, it.i_category, it.i_item_sk
    FROM item it
    INNER JOIN TopCategories tc ON it.i_item_sk = tc.i_item_sk
),
SalesSummary AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(ws.ws_net_profit) AS max_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM web_sales ws
    INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk
),
AddressDetails AS (
    SELECT
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM customer_address ca
    WHERE ca.ca_country = 'USA'
    ORDER BY ca.ca_state, ca.ca_city
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
RankedSales AS (
    SELECT
        s.c_customer_sk,
        SUM(s.total_sales) AS aggregated_sales,
        DENSE_RANK() OVER (ORDER BY SUM(s.total_sales) DESC) AS sales_rank
    FROM SalesSummary s
    GROUP BY s.c_customer_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    rs.aggregated_sales,
    rs.sales_rank,
    ad.full_address
FROM CustomerDemographics cd
LEFT JOIN RankedSales rs ON rs.c_customer_sk IN (
        SELECT c.c_customer_sk
        FROM sales_summary ss
        WHERE ss.total_sales > 1000
    )
LEFT JOIN AddressDetails ad ON ad.ca_address_sk = (
    SELECT c.c_current_addr_sk
    FROM customer c
    WHERE c.c_customer_sk = rs.c_customer_sk
)
WHERE cd.customer_count > 0
ORDER BY cd.cd_gender, rs.sales_rank DESC;
