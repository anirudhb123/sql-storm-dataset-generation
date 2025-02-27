
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws_ext_sales_price) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT OUTER JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ws_ext_sales_price) > (SELECT AVG(ws_ext_sales_price) FROM web_sales)
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        COUNT(ca.ca_address_id) AS address_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state
    HAVING COUNT(ca.ca_address_id) > 1
),
ReturnsSummary AS (
    SELECT 
        COALESCE(SUM(sr_return_amt), 0) AS total_returns,
        COALESCE(SUM(sr_return_tax), 0) AS total_return_tax
    FROM store_returns sr
    WHERE sr_return_quantity > 0
)
SELECT 
    hvc.c_customer_id,
    hvc.c_first_name,
    hvc.c_last_name,
    ra.ca_city,
    ra.ca_state,
    r.total_returns,
    r.total_return_tax,
    rh.total_profit AS avg_profit_per_customer
FROM HighValueCustomers hvc
JOIN CustomerAddresses ra ON hvc.c_customer_id = ra.ca_address_id
CROSS JOIN ReturnsSummary r
JOIN RankedSales rh ON hvc.c_customer_id = rh.ws_bill_customer_sk
WHERE rh.profit_rank <= 10 OR (r.total_returns IS NULL AND r.total_return_tax IS NULL)
ORDER BY hvc.c_customer_id, r.total_returns DESC NULLS LAST;
