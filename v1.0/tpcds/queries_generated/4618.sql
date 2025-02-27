
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as rank_per_item
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = CURRENT_DATE)
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) as rank_per_customer
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
TopItems AS (
    SELECT 
        ris.ws_item_sk,
        SUM(ris.ws_quantity) as total_sold,
        SUM(ris.ws_net_profit) as total_profit
    FROM 
        RankedSales ris
    WHERE 
        ris.rank_per_item <= 5
    GROUP BY 
        ris.ws_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_credit_rating,
    ti.total_sold,
    ti.total_profit,
    CASE 
        WHEN ci.hd_income_band_sk IS NULL THEN 'UNKNOWN'
        ELSE CAST(ci.hd_income_band_sk AS VARCHAR)
    END as income_band,
    COALESCE((
        SELECT STRING_AGG(s.sm_carrier, ', ') 
        FROM ship_mode s 
        WHERE s.sm_ship_mode_sk IN (
            SELECT sr.sm_ship_mode_sk 
            FROM store_returns sr 
            WHERE sr.sr_customer_sk = ci.c_customer_sk
        )
    ), 'NO CARRIERS') AS return_carriers
FROM 
    CustomerInfo ci
JOIN 
    TopItems ti ON ci.c_customer_sk = (
        SELECT ws.ws_bill_customer_sk 
        FROM web_sales ws 
        WHERE ws.ws_item_sk = ti.ws_item_sk 
        ORDER BY ws.ws_net_profit DESC 
        LIMIT 1
    )
WHERE 
    ci.rank_per_customer = 1
ORDER BY 
    ti.total_profit DESC
LIMIT 10;
