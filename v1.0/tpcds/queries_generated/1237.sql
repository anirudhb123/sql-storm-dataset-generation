
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ris.ws_item_sk,
        ri.i_product_name, 
        ri.i_brand, 
        ris.total_quantity, 
        ris.total_net_profit
    FROM 
        RankedSales ris
    JOIN 
        item ri ON ris.ws_item_sk = ri.i_item_sk
    WHERE 
        ris.rank <= 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesDetail AS (
    SELECT 
        ws.ws_order_number,
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ti.i_product_name,
        ti.i_brand,
        ws.ws_quantity,
        ws.ws_net_profit,
        CASE 
            WHEN ws.ws_net_profit < 0 THEN 'Loss'
            ELSE 'Profit'
        END AS profit_status
    FROM 
        web_sales ws
    JOIN 
        TopItems ti ON ws.ws_item_sk = ti.ws_item_sk
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT 
    sd.c_customer_sk,
    sd.c_first_name,
    sd.c_last_name,
    sd.i_product_name,
    sd.i_brand,
    sd.ws_quantity,
    sd.ws_net_profit,
    sd.profit_status,
    COUNT(*) OVER (PARTITION BY sd.c_customer_sk ORDER BY sd.ws_net_profit DESC) AS purchase_count
FROM 
    SalesDetail sd
WHERE 
    sd.ws_net_profit IS NOT NULL
ORDER BY 
    sd.c_customer_sk, 
    sd.ws_net_profit DESC;
