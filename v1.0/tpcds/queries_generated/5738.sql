
WITH CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
),
CombinedStats AS (
    SELECT 
        cs.cd_gender,
        cs.total_customers,
        cs.avg_purchase_estimate,
        cs.total_dependents,
        ss.total_net_profit,
        ss.total_orders,
        ss.avg_sales_price
    FROM 
        CustomerStats cs
    LEFT JOIN 
        SalesStats ss ON cs.total_customers = ss.ws_bill_cdemo_sk
)
SELECT 
    cd_state,
    SUM(total_customers) AS total_customers_by_state,
    SUM(total_orders) AS total_orders_by_state,
    AVG(avg_sales_price) AS avg_sales_price_by_state,
    AVG(avg_purchase_estimate) AS avg_purchase_estimate_by_state,
    SUM(total_dependents) AS total_dependents_by_state
FROM 
    CombinedStats
JOIN 
    customer ON customer.c_current_cdemo_sk = CombinedStats.ws_bill_cdemo_sk
JOIN 
    customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk
GROUP BY 
    cd_state
ORDER BY 
    total_customers_by_state DESC
LIMIT 10;
