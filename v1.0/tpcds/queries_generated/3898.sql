
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS Rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT d_date_sk 
                               FROM date_dim 
                               WHERE d_date = '2022-12-01')
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS CityRank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        COALESCE(SUM(ws.ws_net_paid), 0) AS TotalNetPaid,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        COUNT(DISTINCT ws.ws_item_sk) AS DistinctItems
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT d_date_sk 
                               FROM date_dim 
                               WHERE d_date BETWEEN '2022-11-01' AND '2022-11-30')
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_income_band_sk,
    ci.ca_city,
    ci.ca_state,
    ci.CityRank,
    rs.ws_order_number,
    rs.ws_item_sk,
    rs.ws_quantity,
    rs.ws_net_paid AS DerivedNetPaid,
    ss.TotalNetPaid,
    ss.TotalOrders,
    ss.DistinctItems
FROM 
    CustomerInfo ci
LEFT JOIN 
    RankedSales rs ON ci.c_customer_sk = rs.web_site_sk
CROSS JOIN 
    SalesSummary ss
WHERE 
    ci.CityRank <= 10
ORDER BY 
    ci.ca_city, DerivedNetPaid DESC;
