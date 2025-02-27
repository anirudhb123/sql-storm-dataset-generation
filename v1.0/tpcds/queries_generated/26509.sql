
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
CustomerDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM
        customer_demographics
),
SalesData AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit
    FROM
        web_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        cs_quantity,
        cs_sales_price,
        cs_net_profit
    FROM
        catalog_sales
    UNION ALL
    SELECT
        ss_sold_date_sk,
        ss_item_sk,
        ss_quantity,
        ss_sales_price,
        ss_net_profit
    FROM
        store_sales
),
AggregatedSales AS (
    SELECT
        sd.ws_sold_date_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_profit
    FROM
        SalesData sd
    GROUP BY
        sd.ws_sold_date_sk
)
SELECT
    a.full_address,
    c.cd_gender,
    c.cd_marital_status,
    s.total_quantity,
    s.total_profit,
    ROW_NUMBER() OVER (ORDER BY s.total_profit DESC) AS rank
FROM
    AddressDetails a
JOIN
    customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN
    AggregatedSales s ON c.c_first_sales_date_sk = s.ws_sold_date_sk
WHERE
    a.ca_country = 'USA'
    AND c.cd_purchase_estimate > 1000
ORDER BY
    s.total_profit DESC, a.full_address ASC;
