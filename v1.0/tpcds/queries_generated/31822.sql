
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk, ws_sold_date_sk
), 
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        COALESCE(p.p_discount_active, 'N') AS discount_active
    FROM item i
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        d.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY d.cd_income_band_sk ORDER BY c.c_birth_year DESC) AS rn
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    id.i_product_name,
    id.i_current_price,
    cs.total_quantity,
    cs.total_net_paid,
    ci.cd_gender,
    CASE 
        WHEN ci.cd_income_band_sk IS NOT NULL THEN ib.ib_lower_bound || ' - ' || ib.ib_upper_bound
        ELSE 'Unknown'
    END AS income_band,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers
FROM ItemDetails id
JOIN SalesData cs ON id.i_item_sk = cs.ws_item_sk
LEFT JOIN CustomerInfo ci ON cs.ws_item_sk = ci.c_customer_sk
LEFT JOIN income_band ib ON ci.cd_income_band_sk = ib.ib_income_band_sk
WHERE cs.total_net_paid > 100
AND ci.rn = 1
GROUP BY 
    id.i_product_name, 
    id.i_current_price, 
    cs.total_quantity, 
    cs.total_net_paid,
    ci.cd_gender, 
    ci.cd_income_band_sk
ORDER BY total_net_paid DESC;
