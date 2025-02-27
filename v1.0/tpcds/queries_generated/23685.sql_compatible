
WITH RankedSales AS (
    SELECT
        ws.bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    GROUP BY
        ws.bill_customer_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        COALESCE(cd.cd_dep_count, 0) AS dependents
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
HighValueCustomers AS (
    SELECT
        br.bill_customer_sk,
        br.total_sales,
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.ca_city,
        cd.ca_state,
        cd.dependents 
    FROM
        RankedSales br
    JOIN
        CustomerDetails cd ON br.bill_customer_sk = cd.c_customer_id
    WHERE
        br.total_sales > (SELECT AVG(total_sales) FROM RankedSales) 
        AND cd.ca_state IS NOT NULL
),
CustomerIncome AS (
    SELECT
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        household_demographics hd
    LEFT JOIN
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    cu.c_customer_id,
    cu.cd_gender,
    cu.cd_marital_status,
    cu.ca_city,
    cu.ca_state,
    cu.dependents,
    CASE 
        WHEN ci.ib_lower_bound IS NULL THEN 'Unknown Income'
        ELSE CONCAT('Income Range: ', ci.ib_lower_bound, ' - ', COALESCE(ci.ib_upper_bound, '∞'))
    END AS income_range,
    hc.total_sales
FROM
    HighValueCustomers hc
JOIN
    CustomerDetails cu ON hc.bill_customer_sk = cu.c_customer_id
LEFT JOIN
    CustomerIncome ci ON cu.dependents = ci.hd_demo_sk
WHERE
    hc.total_sales >= (SELECT AVG(total_sales) FROM RankedSales WHERE sales_rank > 1)
    AND (hc.total_sales > 1000 OR cu.ca_city LIKE '%London%' OR cu.ca_state IS NULL)
ORDER BY
    hc.total_sales DESC;
