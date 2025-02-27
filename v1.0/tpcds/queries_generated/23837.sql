
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(ws.order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rank,
        CASE 
            WHEN COUNT(ws.order_number) > 5 THEN 'High Activity'
            WHEN COUNT(ws.order_number) BETWEEN 3 AND 5 THEN 'Moderate Activity'
            ELSE 'Low Activity'
        END AS activity_level
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws.bill_customer_sk
), 
address_summary AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT ca.ca_address_sk) AS unique_addresses
    FROM 
        customer_address ca
    INNER JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_country IS NOT NULL
    GROUP BY 
        ca.ca_country
), 
customer_ranked AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        ib.ib_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY cd.cd_purchase_estimate DESC) as income_rank
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE 
        cd.cd_gender IS NOT NULL AND
        ib.ib_lower_bound IS NOT NULL
)
SELECT 
    cs.bill_customer_sk,
    cs.total_profit,
    cs.order_count,
    cs.activity_level,
    COALESCE(as_.unique_addresses, 0) AS unique_addresses_in_country,
    cr.cd_gender,
    cr.income_rank
FROM 
    sales_summary cs
FULL OUTER JOIN 
    address_summary as_ ON as_.unique_addresses IS NOT NULL
INNER JOIN 
    customer_ranked cr ON cr.cd_demo_sk = cs.bill_customer_sk
WHERE 
    (cr.income_rank IS NOT NULL AND cs.total_profit > 1000) 
    OR (cs.total_profit IS NULL AND cr.cd_gender = 'F')
ORDER BY 
    cs.total_profit DESC NULLS LAST, 
    cs.order_count DESC, 
    unique_addresses_in_country ASC;
