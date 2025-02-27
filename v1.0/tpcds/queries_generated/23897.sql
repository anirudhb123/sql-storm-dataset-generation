
WITH RankedSales AS (
    SELECT 
        ws.ws_customer_sk,
        ws.ws_item_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_customer_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank,
        SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_customer_sk) AS total_spent,
        COUNT(ws.ws_order_number) OVER (PARTITION BY ws.ws_customer_sk) AS orders_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) - 365 
                               FROM date_dim 
                               WHERE d_current_year = 'Y')
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_marital_status,
        cd.cd_gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
LastPurchase AS (
    SELECT 
        ws1.ws_customer_sk,
        MAX(ws1.ws_sold_date_sk) AS last_purchase_date
    FROM 
        web_sales ws1
    GROUP BY 
        ws1.ws_customer_sk
),
FilteredCustomers AS (
    SELECT 
        cs.c_customer_id,
        r.sales_rank,
        cd.cd_gender,
        cd.cd_marital_status,
        lc.last_purchase_date,
        r.total_spent,
        r.orders_count
    FROM 
        customer cs
    JOIN 
        RankedSales r ON cs.c_customer_sk = r.ws_customer_sk
    JOIN 
        CustomerDemographics cd ON cs.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        LastPurchase lc ON cs.c_customer_sk = lc.ws_customer_sk
    WHERE 
        (cd.cd_gender = 'F' AND r.orders_count > 2 AND r.total_spent IS NOT NULL)
        OR (cd.cd_gender = 'M' AND r.total_spent BETWEEN 500 AND 1000)
)
SELECT 
    fc.c_customer_id,
    fc.last_purchase_date,
    CASE 
        WHEN fc.total_spent IS NULL THEN 'No purchases'
        ELSE CAST(fc.total_spent AS VARCHAR(20)) || ' USD'
    END AS total_spent,
    COALESCE(fc.cd_marital_status, 'Unknown') AS marital_status,
    CASE 
        WHEN fc.orders_count > 10 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_status
FROM 
    FilteredCustomers fc
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c_current_addr_sk 
                                                FROM customer 
                                                WHERE c_customer_id = fc.c_customer_id)
ORDER BY 
    fc.last_purchase_date DESC,
    fc.total_spent DESC;
