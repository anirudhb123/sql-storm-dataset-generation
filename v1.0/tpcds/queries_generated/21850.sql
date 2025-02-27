
WITH RankedReturns AS (
    SELECT 
        sr_return_qty,
        sr_returned_date_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_returned_date_sk ORDER BY sr_return_quantity DESC) AS rnk
    FROM 
        store_returns
    WHERE 
        sr_return_quantity IS NOT NULL
),
AggregatedData AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT c_customer_sk) AS unique_customers,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_paid) AS avg_paid,
        MAX(ws_net_paid) AS max_paid
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_state
),
StateDemographics AS (
    SELECT 
        ca_state,
        cd_marital_status,
        COUNT(*) AS demo_count,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd_marital_status IS NOT NULL
    GROUP BY 
        ca_state, cd_marital_status
),
ReturnStatistics AS (
    SELECT 
        r.return_day,
        SUM(r.sr_return_quantity) AS total_returned,
        SUM(CASE WHEN r.sr_return_quantity > 10 THEN r.sr_return_quantity ELSE 0 END) AS high_value_returns
    FROM 
        (SELECT 
            DATE(d.d_date) AS return_day, 
            sr_return_quantity 
         FROM 
            store_returns sr 
         JOIN 
            date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        ) r
    GROUP BY 
        r.return_day
)
SELECT 
    a.ca_state,
    a.unique_customers,
    a.total_profit,
    a.avg_paid,
    a.max_paid,
    d.demo_count,
    d.marital_status,
    r.total_returned,
    COALESCE(r.high_value_returns, 0) AS high_value_returns,
    CASE 
        WHEN r.total_returned < 100 THEN 'Low Returns'
        WHEN r.total_returned BETWEEN 100 AND 500 THEN 'Moderate Returns'
        ELSE 'High Returns'
    END AS return_category
FROM 
    AggregatedData a
LEFT JOIN 
    StateDemographics d ON a.ca_state = d.ca_state
LEFT JOIN 
    ReturnStatistics r ON r.return_day = CURRENT_DATE - INTERVAL '1 day'
WHERE 
    COALESCE(a.unique_customers, 0) > 0
ORDER BY 
    a.total_profit DESC, a.avg_paid DESC;
