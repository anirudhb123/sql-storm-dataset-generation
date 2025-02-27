
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        ca_city,
        ca_state,
        ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca_city, ca_state ORDER BY ca_address_sk DESC) AS rn
    FROM
        customer_address
    WHERE
        ca_country IS NOT NULL
),
DemographicStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT cd_demo_sk) AS demographic_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimate
    FROM
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesData AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_bill_customer_sk
),
ReturnStatistics AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_count
    FROM
        web_returns
    WHERE
        wr_returned_date_sk IS NOT NULL
    GROUP BY
        wr_returning_customer_sk
),
FinalStats AS (
    SELECT
        a.ca_address_id,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        d.cd_gender,
        d.cd_marital_status,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit,
        COALESCE(sd.sales_count, 0) AS sales_count,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        COALESCE(rd.return_count, 0) AS return_count
    FROM
        AddressDetails a
        LEFT JOIN DemographicStats d ON d.demographic_count > 10 -- bizarre filtering condition
        LEFT JOIN SalesData sd ON sd.ws_bill_customer_sk IN (SELECT DISTINCT c_customer_sk FROM customer WHERE c_current_addr_sk = a.ca_address_id)
        LEFT JOIN ReturnStatistics rd ON rd.wr_returning_customer_sk = sd.ws_bill_customer_sk
    WHERE
        a.rn = 1
)
SELECT 
    *,
    CASE 
        WHEN total_net_profit > 1000 THEN 'High Profit'
        WHEN total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM
    FinalStats
WHERE
    (total_net_profit - total_return_amt) > 0 -- only show profitable entries
ORDER BY 
    total_net_profit DESC NULLS LAST;
