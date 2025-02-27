
WITH RecursiveAggregates AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
FilteredSales AS (
    SELECT 
        r.ca_city,
        r.ca_state,
        CASE 
            WHEN r.total_net_profit IS NULL THEN 'No Profit'
            ELSE 'Profit'
        END AS profit_status,
        r.total_net_profit,
        r.customer_count
    FROM 
        RecursiveAggregates r
    WHERE 
        r.profit_rank = 1 AND 
        (r.total_net_profit IS NOT NULL OR r.customer_count > 0)
),
TotalCounts AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_city, ca.ca_state
)
SELECT 
    fs.ca_city,
    fs.ca_state,
    fs.profit_status,
    COALESCE(fs.total_net_profit, 0) AS net_profit,
    fs.customer_count,
    tc.total_customers
FROM 
    FilteredSales fs
FULL OUTER JOIN 
    TotalCounts tc ON fs.ca_city = tc.ca_city AND fs.ca_state = tc.ca_state
ORDER BY 
    fs.ca_state, fs.ca_city
UNION ALL
SELECT 
    'Overall' AS ca_city,
    'N/A' AS ca_state,
    'Total Customers' AS profit_status,
    NULL AS net_profit,
    NULL AS customer_count,
    SUM(tc.total_customers) AS total_customers
FROM 
    TotalCounts tc
WHERE 
    tc.total_customers IS NOT NULL
HAVING 
    SUM(tc.total_customers) > 0;
