
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
DateDetails AS (
    SELECT 
        d_date_sk,
        d_date,
        d_day_name,
        d_month_seq,
        d_year
    FROM 
        date_dim
    WHERE 
        d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_sales_price) AS total_sales_value
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
RankedSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity_sold,
        sd.total_sales_value,
        RANK() OVER (ORDER BY sd.total_sales_value DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    ad.full_address,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    dd.d_date,
    dd.d_day_name,
    rs.total_quantity_sold,
    rs.total_sales_value,
    rs.sales_rank
FROM 
    AddressDetails ad
JOIN 
    CustomerDetails cd ON cd.c_customer_sk = ad.ca_address_sk
JOIN 
    DateDetails dd ON dd.d_date_sk = cd.c_birth_day 
JOIN 
    RankedSales rs ON rs.ws_item_sk = cd.c_customer_sk
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.total_sales_value DESC;
