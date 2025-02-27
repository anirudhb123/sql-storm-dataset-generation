
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS row_num
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
AddressStats AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count, 
        AVG(ca_gmt_offset) AS average_offset
    FROM customer_address
    GROUP BY ca_state
),
HighValueCustomers AS (
    SELECT 
        r.ws_bill_customer_sk
    FROM RankedSales r
    JOIN CustomerDemographics cd ON r.ws_bill_customer_sk = cd.c_customer_sk
    WHERE r.total_profit > (SELECT AVG(total_profit) FROM RankedSales)
      AND cd.row_num = 1
)
SELECT 
    a.ca_state,
    a.address_count,
    a.average_offset,
    COALESCE(hvc.ws_bill_customer_sk, 'No High Value Customer') AS high_value_customer
FROM AddressStats a
LEFT JOIN HighValueCustomers hvc ON a.ca_state = 
    (SELECT ca_state 
     FROM customer_address 
     WHERE ca_address_sk = (SELECT MIN(ca_address_sk) 
                             FROM customer_address WHERE ca_state = a.ca_state))
ORDER BY a.ca_state;
