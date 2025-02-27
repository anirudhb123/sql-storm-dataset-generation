
WITH AddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        SUM(CASE WHEN ca_county LIKE '%County%' THEN 1 ELSE 0 END) AS county_count
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerSummary AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        SUM(cd_dep_count) AS total_dependent_count,
        SUM(cd_dep_employed_count) AS total_dependent_employed_count
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        w_state,
        SUM(ws_net_sales) AS total_net_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM (
        SELECT 
            ws_ship_addr_sk,
            ws_net_paid AS ws_net_sales,
            ws_net_profit
        FROM 
            web_sales
        JOIN 
            customer_address ON ca_address_sk = ws_ship_addr_sk
        UNION ALL
        SELECT 
            ss_addr_sk,
            ss_net_paid AS ss_net_sales,
            ss_net_profit
        FROM 
            store_sales
        JOIN 
            customer_address ON ca_address_sk = ss_addr_sk
    ) AS combined_sales
    JOIN 
        warehouse ON w_warehouse_sk = CASE 
            WHEN ws_ship_addr_sk IS NOT NULL THEN w_warehouse_sk
            ELSE NULL
        END
    GROUP BY 
        w_state
)
SELECT 
    a.ca_state,
    a.unique_addresses,
    a.county_count,
    c.cd_gender,
    c.total_customers,
    c.total_dependent_count,
    c.total_dependent_employed_count,
    s.total_net_sales,
    s.avg_net_profit
FROM 
    AddressSummary a
JOIN 
    CustomerSummary c ON a.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk IN 
                                        (SELECT ca_address_sk FROM customer WHERE c_customer_sk = c.total_customers))
LEFT JOIN 
    SalesSummary s ON s.w_state = a.ca_state;
