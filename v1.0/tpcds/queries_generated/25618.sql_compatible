
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_name, ', ' ORDER BY ca_street_name) AS unique_street_names,
        STRING_AGG(DISTINCT ca_zip, ', ' ORDER BY ca_zip) AS unique_zip_codes
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
),
DailySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_sales_price) AS total_sales,
        STRING_AGG(DISTINCT CAST(ws.ws_web_page_sk AS VARCHAR), ', ') AS sold_item_ids
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    ac.ca_city,
    ac.address_count,
    ac.unique_street_names,
    ac.unique_zip_codes,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    cd.avg_purchase_estimate,
    ds.d_year,
    ds.d_month_seq,
    ds.total_sales,
    ds.sold_item_ids
FROM 
    AddressCounts ac
JOIN 
    CustomerDemographics cd ON ac.address_count > 5
JOIN 
    DailySales ds ON ds.total_sales > 5000
ORDER BY 
    ac.ca_city, cd.cd_gender, ds.d_year DESC, ds.d_month_seq DESC;
