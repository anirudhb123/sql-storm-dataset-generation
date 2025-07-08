
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS SalesRank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 30
),
PromotionsApplied AS (
    SELECT 
        cs_order_number,
        SUM(cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT cs_item_sk) AS distinct_items
    FROM catalog_sales
    WHERE cs_order_number IN (SELECT ws_order_number FROM SalesCTE WHERE SalesRank = 1)
    GROUP BY cs_order_number
),
AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state) AS full_address
    FROM customer_address
    WHERE ca_state IS NOT NULL
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.full_address,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS GenderRanking
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(SUM(pa.total_sales), 0) AS total_promotional_sales,
    COALESCE(SUM(SC.ws_net_profit), 0) AS total_web_sales_profit,
    COUNT(DISTINCT SC.ws_order_number) AS total_orders,
    MAX(cd.GenderRanking) AS max_gender_rank
FROM CustomerDetails cd
LEFT JOIN PromotionsApplied pa ON pa.cs_order_number IN (
    SELECT ws_order_number FROM web_sales WHERE ws_bill_customer_sk = cd.c_customer_sk
)
LEFT JOIN SalesCTE SC ON SC.ws_order_number = pa.cs_order_number
GROUP BY 
    cd.c_first_name, 
    cd.c_last_name,
    cd.cd_gender, 
    cd.cd_marital_status
HAVING MAX(cd.GenderRanking) > 5
ORDER BY total_promotional_sales DESC, total_orders DESC;
