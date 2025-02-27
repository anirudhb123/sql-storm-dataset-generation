
WITH AddressInfo AS (
    SELECT 
        ca.city,
        ca.state,
        ca.country,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        STRING_AGG(DISTINCT c.c_first_name || ' ' || c.c_last_name, ', ') AS customer_names
    FROM
        customer_address ca 
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.city, ca.state, ca.country
),
GenderStats AS (
    SELECT 
        d.gender,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.purchase_estimate) AS avg_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    GROUP BY 
        cd.gender
),
SalesStats AS (
    SELECT
        s.s_state AS state,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM
        store_sales ss
    JOIN
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_state
)
SELECT 
    ai.city,
    ai.state,
    ai.country,
    ai.customer_count,
    ai.customer_names,
    gs.gender,
    gs.customer_count AS gender_customer_count,
    gs.avg_purchase_estimate,
    ss.total_sales,
    ss.total_profit
FROM 
    AddressInfo ai
LEFT JOIN
    GenderStats gs ON ai.customer_count > 0
LEFT JOIN 
    SalesStats ss ON ai.state = ss.state
ORDER BY 
    ai.customer_count DESC, gs.gender;
