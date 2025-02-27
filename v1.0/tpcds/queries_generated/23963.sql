
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_returned_date_sk,
        sr_return_quantity,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT sr_returned_date_sk) AS return_count,
        AVG(ws.ws_net_paid) AS avg_spent_per_purchase
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN RankedReturns rr ON c.c_customer_sk = rr.sr_customer_sk AND rr.rnk <= 2
    WHERE c.c_birth_year BETWEEN 1970 AND 1980
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY c.c_customer_id
    HAVING COUNT(ws.ws_order_number) > 5
       AND AVG(ws.ws_net_paid) > 100
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT hc.hd_demo_sk) AS demographic_count
    FROM household_demographics hc
    JOIN customer_demographics cd ON hc.hd_demo_sk = cd.cd_demo_sk
    WHERE hc.hd_buy_potential = 'High'
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
TopWarehouses AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM warehouse w
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city IS NOT NULL
    GROUP BY w.w_warehouse_id
    HAVING SUM(ws.ws_net_paid) > 10000
    ORDER BY total_sales DESC
    LIMIT 5
)

SELECT 
    cdc.cd_gender,
    cdc.cd_marital_status,
    hvc.c_customer_id,
    hvc.total_spent,
    hvc.return_count,
    tw.w_warehouse_id,
    tw.total_sales
FROM HighValueCustomers hvc
JOIN CustomerDemographics cdc ON 1=1
CROSS JOIN TopWarehouses tw
LEFT JOIN customer_address ca ON ca.ca_address_sk = hvc.c_customer_sk
WHERE NOT EXISTS (
    SELECT 1 
    FROM store_returns sr
    WHERE sr.sr_customer_sk = hvc.c_customer_id 
      AND sr.sr_return_quantity > (
          SELECT AVG(sr_inner.sr_return_quantity) 
          FROM store_returns sr_inner 
          WHERE sr_inner.sr_customer_sk = sr.sr_customer_sk
      )
)
ORDER BY hvc.total_spent DESC, tw.total_sales DESC;
