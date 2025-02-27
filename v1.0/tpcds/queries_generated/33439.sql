
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, ws_item_sk
),
TopSales AS (
    SELECT 
        ws_item_sk, 
        total_quantity,
        total_profit 
    FROM 
        SalesCTE
    WHERE 
        item_rank <= 5
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        COUNT(ws.ws_order_number) AS promo_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(c.c_customer_sk) AS customer_count 
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender
)
SELECT 
    ca.city,
    ca.state,
    SUM(ts.total_quantity) AS total_sales_quantity,
    SUM(ts.total_profit) AS total_sales_profit,
    STRING_AGG(DISTINCT d.cd_gender) AS customer_genders,
    COALESCE(SUM(p.promo_count), 0) AS total_promotions
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    TopSales ts ON ts.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_ship_customer_sk = c.c_customer_sk)
LEFT JOIN 
    Promotions p ON p.p_promo_sk IN (SELECT ws_promo_sk FROM web_sales WHERE ws_ship_customer_sk = c.c_customer_sk)
LEFT JOIN 
    Demographics d ON d.cd_demo_sk = c.c_current_cdemo_sk
GROUP BY 
    ca.city, ca.state
HAVING 
    SUM(ts.total_profit) IS NOT NULL
ORDER BY 
    total_sales_profit DESC
FETCH FIRST 10 ROWS ONLY;
