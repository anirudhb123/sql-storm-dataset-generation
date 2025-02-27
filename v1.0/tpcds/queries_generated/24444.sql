
WITH RankedSales AS (
    SELECT
        CASE 
            WHEN ws_bill_customer_sk IS NULL THEN cs_bill_customer_sk 
            ELSE ws_bill_customer_sk 
        END AS customer_sk,
        SUM(COALESCE(ws_net_profit, 0) + COALESCE(cs_net_profit, 0)) AS total_profit,
        RANK() OVER (PARTITION BY CASE 
                                    WHEN ws_bill_customer_sk IS NULL THEN 'Catalog' 
                                    ELSE 'Web' 
                                   END 
                     ORDER BY SUM(COALESCE(ws_net_profit, 0) + COALESCE(cs_net_profit, 0)) DESC) AS rank
    FROM web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    GROUP BY customer_sk
),
TopCustomers AS (
    SELECT 
        customer_sk,
        total_profit
    FROM RankedSales
    WHERE rank <= 5
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN TopCustomers tc ON c.c_customer_sk = tc.customer_sk
)
SELECT 
    c.c_customer_id,
    SUM(COALESCE(ws.ws_sales_price, 0) - COALESCE(ws.ws_ext_discount_amt, 0)) AS net_sales,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT ca.ca_city) AS distinct_cities,
    STRING_AGG(DISTINCT CONCAT(cd.cd_gender, ' - ', cd.cd_marital_status), '; ') AS demographics_overview
FROM CustomerDetails cd
LEFT JOIN web_sales ws ON cd.c_customer_id = ws.ws_bill_customer_sk
WHERE cd.ca_state IS NOT NULL AND cd.ca_city NOT IN ('Unknown', 'N/A')
GROUP BY cd.c_customer_id
ORDER BY net_sales DESC
LIMIT 10;
