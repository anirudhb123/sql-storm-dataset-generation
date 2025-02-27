
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.item_sk,
        ws_sales_price,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws_sales_price IS NOT NULL
),
StoreInventory AS (
    SELECT 
        inv.item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.item_sk
),
CustomerDetails AS (
    SELECT 
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        c.c_customer_id,
        COUNT(DISTINCT c.c_customer_sk) OVER (PARTITION BY ca.ca_city) AS city_customer_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_city IS NOT NULL
),
PromotionsUsed AS (
    SELECT 
        cs.cs_item_sk,
        COUNT(DISTINCT cs.cs_order_number) AS promo_count,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM 
        catalog_sales cs
    LEFT JOIN 
        promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y' 
        AND (cs.cs_net_profit IS NOT NULL OR cs.cs_net_profit < 0)
    GROUP BY 
        cs.cs_item_sk
)
SELECT 
    cd.ca_city, 
    cd.cd_gender, 
    cd.cd_marital_status,
    SUM(RS.ws_sales_price) AS total_sales,
    COALESCE(SI.total_quantity, 0) AS available_inventory,
    COALESCE(PU.promo_count, 0) AS promotions_used,
    COALESCE(PU.total_net_profit, 0) AS total_net_profit
FROM 
    CustomerDetails cd
LEFT JOIN 
    RankedSales RS ON cd.c_customer_id = RS.web_site_id
LEFT JOIN 
    StoreInventory SI ON RS.item_sk = SI.item_sk
LEFT JOIN 
    PromotionsUsed PU ON RS.item_sk = PU.cs_item_sk
WHERE 
    cd.city_customer_count > 10 
    AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status = 'S')
GROUP BY 
    cd.ca_city, cd.cd_gender, cd.cd_marital_status
HAVING 
    SUM(RS.ws_sales_price) > (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_sales_price IS NOT NULL)
ORDER BY 
    total_sales DESC, 
    cd.ca_city ASC;
