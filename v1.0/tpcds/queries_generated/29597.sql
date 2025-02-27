
WITH AddressCounts AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        STRING_AGG(CAST(ca_city AS varchar), ', ') AS cities,
        STRING_AGG(CAST(ca_zip AS varchar) ORDER BY ca_zip) AS zips
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        c.c_customer_id,
        ci.c_first_name,
        ci.c_last_name,
        ci.c_email_address,
        ad.ca_state
    FROM 
        customer_demographics cd
    JOIN 
        customer ci ON cd.cd_demo_sk = ci.c_current_cdemo_sk
    JOIN 
        customer_address ad ON ci.c_current_addr_sk = ad.ca_address_sk
),
DateRange AS (
    SELECT 
        d_year, 
        d_month_seq, 
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year, d_month_seq
),
FinalReport AS (
    SELECT 
        ac.ca_state, 
        ac.address_count, 
        ac.cities, 
        ac.zips,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(dr.order_count) AS total_orders
    FROM 
        AddressCounts ac
    JOIN 
        CustomerDemographics cd ON ac.ca_state = cd.ca_state
    JOIN 
        DateRange dr ON dr.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY 
        ac.ca_state, ac.address_count, ac.cities, ac.zips, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ca_state,
    address_count,
    cities,
    zips,
    cd_gender,
    cd_marital_status,
    total_orders
FROM 
    FinalReport
ORDER BY 
    total_orders DESC, 
    address_count DESC;
