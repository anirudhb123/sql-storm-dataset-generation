
WITH RankedReturns AS (
    SELECT
        sr_customer_sk,
        sr_item_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY sr_return_quantity DESC) AS rn
    FROM
        store_returns
),
HighReturnCustomers AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_qty
    FROM
        RankedReturns
    WHERE
        rn = 1
    GROUP BY
        sr_customer_sk
    HAVING
        SUM(sr_return_quantity) > 10
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating 
        END AS credit_rating
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        c.c_birth_year IS NOT NULL
),
RecentPurchases AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        MIN(d.d_date) AS first_purchase_date,
        MAX(d.d_date) AS last_purchase_date
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = YEAR(CURDATE())
    GROUP BY
        ws_bill_customer_sk
),
FilteredCustomers AS (
    SELECT
        cd.c_customer_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.ca_city,
        cd.ca_state,
        rp.total_sales,
        rp.order_count,
        rp.first_purchase_date,
        rp.last_purchase_date,
        hrc.total_return_qty
    FROM
        CustomerDetails cd
    LEFT JOIN
        RecentPurchases rp ON cd.c_customer_id = rp.ws_bill_customer_sk
    LEFT JOIN
        HighReturnCustomers hrc ON cd.c_customer_sk = hrc.sr_customer_sk
    WHERE
        hrc.total_return_qty IS NULL OR hrc.total_return_qty > 5
)
SELECT 
    fc.c_customer_id,
    CONCAT(fc.c_first_name, ' ', fc.c_last_name) AS full_name,
    fc.ca_city,
    fc.ca_state,
    COALESCE(fc.total_sales, 0) AS total_sales,
    COALESCE(fc.order_count, 0) AS total_orders,
    DATEDIFF(CURDATE(), fc.first_purchase_date) AS days_since_first_purchase,
    CASE
        WHEN fc.last_purchase_date IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status,
    CASE 
        WHEN fc.total_sales IS NOT NULL AND fc.total_sales > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value
FROM
    FilteredCustomers fc
ORDER BY
    fc.total_sales DESC NULLS LAST
LIMIT 100;
