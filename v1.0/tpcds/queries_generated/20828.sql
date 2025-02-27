
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.item_sk,
        ws.ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank,
        ws.ws_net_profit,
        ws.ws_quantity,
        DENSE_RANK() OVER (ORDER BY ws.ws_net_profit DESC) AS profit_dominance
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
    AND 
        ws.ws_quantity > 0
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY c.c_birth_year DESC) AS marital_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        rs.web_site_sk,
        COUNT(rs.ws_order_number) AS total_sales,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.web_site_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ss.total_sales,
    ss.total_net_profit,
    si.outer_value,
    si.margin_of_error
FROM 
    CustomerInfo ci
JOIN 
    SalesSummary ss ON ss.web_site_sk IN (
        SELECT ws.web_site_sk
        FROM web_sales ws
        WHERE 
            ws.ws_net_profit > (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2)
    )
LEFT JOIN 
    (
        SELECT 
            iv.inv_item_sk, 
            AVG(COALESCE(iv.inv_quantity_on_hand, 0)) AS outer_value,
            STDDEV(iv.inv_quantity_on_hand) AS margin_of_error
        FROM 
            inventory iv
        GROUP BY 
            iv.inv_item_sk
        HAVING 
            COUNT(DISTINCT iv.inv_date_sk) > 1
    ) si ON si.inv_item_sk = ci.c_customer_sk
WHERE 
    ci.marital_rank = 1
AND 
    ci.cd_purchase_estimate IS NOT NULL
ORDER BY 
    ss.total_net_profit DESC, 
    ci.c_first_name ASC
LIMIT 10;
