
WITH AddressAggregate AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count, 
        LISTAGG(ca_street_name, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
),
CustomerSummary AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
DateSummary AS (
    SELECT 
        d_year, 
        d_month_seq, 
        COUNT(ws_order_number) AS sales_count
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year, d_month_seq
),
SalesData AS (
    SELECT 
        ADDRESS.ca_city, 
        ADDRESS.ca_state, 
        CUSTOMER.cd_gender, 
        CUSTOMER.cd_marital_status,
        DATE.d_year,
        DATE.d_month_seq,
        DATE.sales_count,
        ADDRESS.address_count,
        CUSTOMER.customer_count,
        CUSTOMER.avg_estimate,
        ROW_NUMBER() OVER (PARTITION BY ADDRESS.ca_city, CUSTOMER.cd_gender ORDER BY DATE.sales_count DESC) AS rank
    FROM 
        AddressAggregate AS ADDRESS
    JOIN 
        CustomerSummary AS CUSTOMER ON ADDRESS.ca_state = CUSTOMER.cd_marital_status
    JOIN 
        DateSummary AS DATE ON DATE.d_year = EXTRACT(YEAR FROM CURRENT_TIMESTAMP)
)
SELECT 
    ca_city, 
    ca_state, 
    cd_gender, 
    cd_marital_status, 
    AVG(avg_estimate) AS avg_customer_estimate, 
    SUM(sales_count) AS total_sales_count
FROM 
    SalesData
WHERE 
    rank <= 10
GROUP BY 
    ca_city, ca_state, cd_gender, cd_marital_status, avg_estimate
ORDER BY 
    total_sales_count DESC;
