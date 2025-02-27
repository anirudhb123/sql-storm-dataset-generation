
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                 AND (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2024)
    GROUP BY 
        ws.web_site_sk
),
FilteredCustomerData AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'UNDEFINED') AS gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        h.hd_buy_potential,
        COUNT(DISTINCT CASE WHEN ws.ws_ship_date_sk IS NOT NULL THEN ws.ws_order_number END) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        (SELECT hd_demo_sk, COUNT(*) AS hd_buy_potential FROM household_demographics GROUP BY hd_demo_sk) h ON h.hd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        c.c_customer_sk, gender, cd.cd_marital_status, hd.hd_income_band_sk, h.hd_buy_potential
)
SELECT 
    fcd.c_customer_sk,
    fcd.gender,
    fcd.marital_status,
    rb.total_net_profit,
    fcd.total_orders,
    (CASE 
        WHEN fcd.total_orders > 5 THEN 'Frequent Buyer' 
        ELSE 'Occasional Buyer' 
    END) AS buyer_type
FROM 
    FilteredCustomerData fcd
INNER JOIN 
    RankedSales rb ON fcd.c_customer_sk = rb.web_site_sk
WHERE 
    rb.rank <= 10
ORDER BY 
    rb.total_net_profit DESC, fcd.c_customer_sk;
