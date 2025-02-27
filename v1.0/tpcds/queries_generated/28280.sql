
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ca.ca_state,
        ca.ca_zip,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_order_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_income_band_sk, ca.ca_state, ca.ca_zip
),
income_distribution AS (
    SELECT
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL THEN 'Unknown'
            ELSE CONCAT(ib.ib_lower_bound, ' - ', ib.ib_upper_bound)
        END AS income_range,
        COUNT(*) AS customer_count
    FROM 
        household_demographics hd
    JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
),
state_stats AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_products_sold
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    id.income_range,
    ss.unique_customers,
    ss.total_products_sold,
    cd.total_orders,
    cd.avg_order_profit
FROM 
    customer_data cd
JOIN 
    income_distribution id ON cd.cd_income_band_sk = id.ib_income_band_sk
JOIN 
    state_stats ss ON cd.ca_state = ss.ca_state
WHERE 
    cd.total_orders > 0 
ORDER BY 
    cd.avg_order_profit DESC;
