
WITH AddressCount AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
Demographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
ItemInformation AS (
    SELECT 
        i_category,
        COUNT(*) AS total_items,
        AVG(i_current_price) AS avg_price
    FROM 
        item
    GROUP BY 
        i_category
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS sales_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    a.ca_state,
    d.cd_gender,
    i.i_category,
    i.total_items,
    i.avg_price,
    s.total_profit,
    s.sales_count,
    CONCAT(a.ca_state, ' - ', d.cd_gender, ' - ', i.i_category) AS benchmark_key
FROM 
    AddressCount a
JOIN 
    Demographics d ON a.total_addresses > 100
JOIN 
    ItemInformation i ON i.total_items > 50
JOIN 
    SalesData s ON s.sales_count > 10
ORDER BY 
    total_profit DESC, total_items DESC;
