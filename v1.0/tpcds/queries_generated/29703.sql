
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
DemographicCounts AS (
    SELECT 
        cd_gender,
        COUNT(*) AS total_customers
    FROM 
        customer demographics
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_gender
),
SalesData AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
),
FormattedData AS (
    SELECT 
        dd.d_date as order_date,
        ac.ca_state,
        dc.cd_gender,
        sd.total_sales,
        sd.total_orders,
        ROW_NUMBER() OVER (PARTITION BY ac.ca_state, dc.cd_gender ORDER BY sd.total_sales DESC) AS rank
    FROM 
        date_dim dd
    JOIN 
        SalesData sd ON dd.d_date_sk = sd.ws_ship_date_sk
    JOIN 
        AddressCounts ac ON ac.ca_state = dd.d_month_seq
    JOIN 
        DemographicCounts dc ON dc.total_customers > 0
)
SELECT 
    order_date,
    ca_state,
    cd_gender,
    total_sales,
    total_orders
FROM 
    FormattedData
WHERE 
    rank <= 5
ORDER BY 
    ca_state, cd_gender, total_sales DESC;
