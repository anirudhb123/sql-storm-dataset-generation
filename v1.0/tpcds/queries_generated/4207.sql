
WITH SalesAggregates AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        AVG(ws.net_paid_inc_ship_tax) AS avg_order_value,
        MAX(ws.net_profit) AS max_order_profit,
        MIN(ws.net_profit) AS min_order_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
        AND ws.ship_mode_sk IN (SELECT sm_ship_mode_sk 
                                  FROM ship_mode 
                                  WHERE sm_type = 'Delivery')
    GROUP BY 
        ws.web_site_id
),
CustomerIncome AS (
    SELECT 
        cd_demo_sk,
        SUM(hd_income_band_sk) AS total_income_bands,
        COUNT(hd_demo_sk) AS household_count
    FROM 
        household_demographics hd
    JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        cd_demo_sk
)
SELECT 
    sa.web_site_id,
    sa.total_net_profit,
    sa.total_orders,
    sa.avg_order_value,
    ci.total_income_bands,
    ci.household_count,
    CASE 
        WHEN sa.total_net_profit IS NULL THEN 'No Profits'
        WHEN sa.total_net_profit > 10000 THEN 'High Performer'
        ELSE 'Regular Performer'
    END AS performance_category
FROM 
    SalesAggregates sa
LEFT JOIN 
    CustomerIncome ci ON sa.total_orders = ci.household_count
WHERE 
    sa.avg_order_value > (SELECT AVG(avg_order_value) FROM SalesAggregates)
ORDER BY 
    sa.total_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
