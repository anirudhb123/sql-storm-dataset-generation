
WITH RECURSIVE address_cte AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state,
        1 AS depth
    FROM 
        customer_address 
    WHERE 
        ca_state IS NOT NULL

    UNION ALL

    SELECT 
        a.ca_address_sk, 
        a.ca_city, 
        a.ca_state,
        c.depth + 1
    FROM 
        customer_address a
    JOIN 
        address_cte c ON a.ca_city = c.ca_city 
    WHERE 
        c.depth < 5
), 
gender_income AS (
    SELECT 
        cd.cd_gender, 
        ib.ib_income_band_sk,
        SUM(cd.cd_purchase_estimate) AS total_purchase
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        cd.cd_gender, ib.ib_income_band_sk
), 
sales_summary AS (
    SELECT 
        s_store_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ws_net_profit) DESC) AS ranking
    FROM 
        web_sales ws
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    GROUP BY 
        s_store_sk
),
yearly_sales AS (
    SELECT 
        d_year, 
        SUM(ws_net_profit) AS annual_sales
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
    HAVING 
        SUM(ws_net_profit) IS NOT NULL
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    g.cd_gender,
    g.ib_income_band_sk,
    SUM(g.total_purchase) AS total_income,
    MAX(ss.total_profit) AS max_store_profit,
    AVG(y.annual_sales) AS avg_yearly_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_sales,
    'Active' AS status
FROM 
    address_cte ca
LEFT JOIN 
    gender_income g ON ca.ca_city = g.cd_gender OR g.ib_income_band_sk IS NULL
LEFT JOIN 
    sales_summary ss ON ss.s_store_sk = ca.ca_address_sk
LEFT JOIN 
    yearly_sales y ON y.d_year = EXTRACT(YEAR FROM CURRENT_DATE) 
WHERE 
    ca.depth = 1 
    AND (g.total_purchase IS NOT NULL OR g.total_purchase < 1000)
    AND (g.cd_gender IS NOT NULL AND g.cd_gender = 'F' OR g.cd_gender = 'M')
GROUP BY 
    ca.ca_city, 
    ca.ca_state, 
    g.cd_gender, 
    g.ib_income_band_sk
HAVING 
    MAX(ss.total_profit) > 5000 OR COUNT(DISTINCT ws.ws_order_number) > 50
ORDER BY 
    total_income DESC, 
    max_store_profit DESC
LIMIT 100;
