
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(ws.order_number) AS total_orders,
        AVG(ws.net_paid_inc_tax) AS avg_payment_per_order,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    LEFT JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        return_summary rs ON ws.order_number = rs.order_number
    WHERE 
        dd.d_year = 2023
        AND (c.c_first_name LIKE '%a%' OR c.c_last_name LIKE '%b%')
        AND ws.net_profit IS NOT NULL
    GROUP BY 
        ws.web_site_id
),
ReturnSummary AS (
    SELECT 
        ws.web_site_id,
        COUNT(rs.returning_customer_sk) AS total_returns,
        SUM(COALESCE(rs.return_amt, 0)) AS total_return_amount
    FROM 
        web_sales ws
    LEFT JOIN 
        web_returns rs ON ws.order_number = rs.order_number
    GROUP BY 
        ws.web_site_id
)
SELECT 
    sd.web_site_id,
    sd.total_net_profit,
    sd.total_orders,
    sd.avg_payment_per_order,
    rs.total_returns,
    rs.total_return_amount,
    CASE 
        WHEN sd.total_net_profit > 10000 THEN 'High Profit'
        WHEN sd.total_net_profit BETWEEN 5000 AND 10000 THEN 'Moderate Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    SalesData sd
LEFT JOIN 
    ReturnSummary rs ON sd.web_site_id = rs.web_site_id
WHERE 
    sd.profit_rank <= 5
ORDER BY 
    sd.total_net_profit DESC;

-- Additional query for NULL logic corner cases
SELECT 
    ca.city,
    COUNT(c.c_customer_sk) AS customer_count,
    COALESCE(AVG(cd_purchase_estimate), 0) AS avg_purchase_estimate,
    STRING_AGG(CASE WHEN c.c_birth_country IS NULL THEN 'Unknown Country' ELSE c.c_birth_country END, ', ') AS birth_countries
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_city IS NOT NULL
GROUP BY 
    ca.city
HAVING 
    AVG(cd_purchase_estimate) IS NOT NULL OR COUNT(c.c_customer_sk) > 0
ORDER BY 
    customer_count DESC;
