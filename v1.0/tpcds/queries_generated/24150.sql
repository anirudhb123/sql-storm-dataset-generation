
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk, 
        ws.ship_date_sk, 
        ws.item_sk, 
        ws.quantity, 
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.net_profit DESC) AS rank_profit,
        SUM(ws.quantity) OVER (PARTITION BY ws.bill_customer_sk) AS total_quantity,
        LEAD(ws.net_profit) OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.net_profit DESC) AS next_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ship_date_sk BETWEEN 20000101 AND 20011231
), HighValueCustomers AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT rs.bill_customer_sk) AS high_value_customers,
        SUM(rs.total_quantity) AS total_bought,
        AVG(rs.next_profit - rs.net_profit) AS average_profit_difference
    FROM 
        RankedSales rs
    JOIN 
        customer_demographics cd ON rs.bill_customer_sk = cd.cd_demo_sk
    WHERE 
        rs.rank_profit = 1 
        AND rs.net_profit > (SELECT AVG(net_profit) FROM RankedSales)
    GROUP BY 
        cd.cd_gender
), CustomerAddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CASE 
            WHEN ca.ca_gmt_offset IS NULL THEN 'GMT Not Specified' 
            ELSE 'GMT ' || CAST(ca.ca_gmt_offset AS VARCHAR) 
        END AS gmt_info
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('CA', 'NY') OR ca.ca_country IS NULL
)
SELECT 
    hvc.cd_gender,
    hvc.high_value_customers,
    hvc.total_bought,
    cai.ca_city,
    cai.gmt_info
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    CustomerAddressInfo cai ON hvc.high_value_customers > 0
WHERE 
    (hvc.high_value_customers IS NOT NULL OR hvc.total_bought > 1000)
ORDER BY 
    hvc.total_bought DESC;
