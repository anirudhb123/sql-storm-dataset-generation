
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rnk
    FROM web_sales
), 
SalesSummary AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        AVG(cs_net_profit) AS avg_net_profit
    FROM catalog_sales
    GROUP BY cs_item_sk
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
), 
AddressJoin AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS city_customer_count
    FROM customer
    JOIN customer_address ON c_current_addr_sk = ca_address_sk
    GROUP BY ca_city
)
SELECT 
    COALESCE(rs.ws_item_sk, cs.cs_item_sk) AS item_sk,
    COALESCE(rs.ws_order_number, cs.cs_order_number) AS order_number,
    COALESCE(rs.ws_net_profit, 0) AS net_profit,
    ss.total_quantity,
    ss.avg_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    aj.ca_city,
    aj.city_customer_count
FROM RankedSales rs
FULL OUTER JOIN SalesSummary ss ON rs.ws_item_sk = ss.cs_item_sk
FULL OUTER JOIN CustomerDemographics cd ON cd.customer_count IS NOT NULL
JOIN AddressJoin aj ON aj.city_customer_count > (SELECT AVG(customer_count) FROM CustomerDemographics)
WHERE (rs.rnk = 1 OR ss.total_quantity IS NOT NULL)
ORDER BY net_profit DESC, total_quantity DESC
LIMIT 100;
