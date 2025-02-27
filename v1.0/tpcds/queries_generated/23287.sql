
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
DemographicsWithIncome AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'UNKNOWN'
            WHEN cd.cd_purchase_estimate >= 0 THEN 'BUYER'
            ELSE 'NON-BUYER'
        END AS purchase_status
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
TopStores AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
    HAVING 
        SUM(ss.ss_net_profit) > 10000
)
SELECT 
    c.c_customer_id,
    ds.cd_gender,
    ds.purchase_status,
    COALESCE(cs.total_orders, 0) AS orders_count,
    COALESCE(cs.total_profit, 0) AS profit,
    (SELECT COUNT(DISTINCT ws_item_sk) 
        FROM web_sales 
        WHERE ws_ship_customer_sk = c.c_customer_sk) AS total_items_shipped,
    s.s_store_name
FROM 
    customer c
LEFT JOIN 
    CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    DemographicsWithIncome ds ON c.c_current_cdemo_sk = ds.cd_demo_sk
LEFT JOIN 
    TopStores s ON s.s_store_sk = ANY(ARRAY(
        SELECT s_store_sk
        FROM store_sales
        WHERE ss_customer_sk = c.c_customer_sk
        GROUP BY s_store_sk
        ORDER BY SUM(ss_net_profit) DESC
        LIMIT 5
    ))
WHERE 
    (ds.cd_marital_status IS NULL OR ds.cd_marital_status = 'S') 
    AND ds.ib_income_band_sk IS NOT NULL
    AND EXISTS (SELECT 1 
                FROM web_sales ws 
                WHERE ws.ws_bill_customer_sk = c.c_customer_sk 
                AND ws.ws_sold_date_sk = (
                    SELECT MAX(ws_inner.ws_sold_date_sk) 
                    FROM web_sales ws_inner 
                    WHERE ws_inner.ws_bill_customer_sk = c.c_customer_sk))
ORDER BY 
    profit DESC, 
    orders_count ASC;
