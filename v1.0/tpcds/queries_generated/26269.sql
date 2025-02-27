
WITH AddressCounts AS (
    SELECT
        ca_city,
        COUNT(*) AS address_count,
        STRING_AGG(DISTINCT ca_street_name || ' ' || ca_street_number, ', ') AS street_details
    FROM
        customer_address
    GROUP BY
        ca_city
),
CustomerInfo AS (
    SELECT
        c.c_customer_id,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ad.address_count,
        ad.street_details
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        AddressCounts ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesStats AS (
    SELECT
        c.customer_id,
        SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales,
        SUM(COALESCE(ws.ws_coupon_amt, 0)) AS total_coupons,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        CustomerInfo c ON c.c_customer_id = ws.ws_bill_customer_sk
    GROUP BY
        c.customer_id
)
SELECT
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.address_count,
    ci.street_details,
    ss.total_sales,
    ss.total_coupons,
    ss.order_count
FROM
    CustomerInfo ci
JOIN
    SalesStats ss ON ci.c_customer_id = ss.customer_id
ORDER BY
    ss.total_sales DESC,
    ci.full_name;
