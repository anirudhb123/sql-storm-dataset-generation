
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER(PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2459995 AND 2462625
    GROUP BY ws.bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cust.c_customer_sk,
        cust.c_first_name,
        cust.c_last_name,
        cust.c_email_address,
        dem.cd_marital_status,
        dem.cd_gender,
        dem.cd_purchase_estimate,
        ad.ca_city,
        ad.ca_state,
        sales.total_profit,
        sales.order_count
    FROM customer cust
    JOIN customer_demographics dem ON cust.c_current_cdemo_sk = dem.cd_demo_sk
    JOIN customer_address ad ON cust.c_current_addr_sk = ad.ca_address_sk
    JOIN RankedSales sales ON cust.c_customer_sk = sales.bill_customer_sk
    WHERE sales.rank = 1
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.c_email_address,
    CONCAT(hvc.ca_city, ', ', hvc.ca_state) AS location,
    hvc.cd_marital_status,
    hvc.cd_gender,
    hvc.cd_purchase_estimate,
    COALESCE(
        (SELECT COUNT(*) 
         FROM store_sales ss 
         WHERE ss.ss_customer_sk = hvc.c_customer_sk AND ss.ss_sold_date_sk BETWEEN 2459995 AND 2462625),
        0
    ) AS num_store_sales,
    COALESCE(
        (SELECT COUNT(*) 
         FROM catalog_sales cs 
         WHERE cs.cs_bill_customer_sk = hvc.c_customer_sk AND cs.cs_sold_date_sk BETWEEN 2459995 AND 2462625),
        0
    ) AS num_catalog_sales
FROM HighValueCustomers hvc
ORDER BY hvc.total_profit DESC
LIMIT 10;
