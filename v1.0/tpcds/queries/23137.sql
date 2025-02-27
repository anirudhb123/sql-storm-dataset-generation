
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        sr_return_quantity,
        RANK() OVER (PARTITION BY sr_customer_sk ORDER BY sr_return_amt DESC) AS return_rank
    FROM store_returns
    WHERE sr_return_quantity > 0
),
BaseSales AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_ship_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        COALESCE(cd_dep_count, 0) AS dep_count,
        CASE 
            WHEN cd_credit_rating = 'Good' THEN 'A'
            WHEN cd_credit_rating = 'Fair' THEN 'B'
            ELSE 'C'
        END AS credit_band
    FROM customer_demographics
),
CustomersWithReturns AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        COALESCE(SUM(rr.sr_return_quantity), 0) AS total_return_quantity,
        DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY COALESCE(SUM(rr.sr_return_quantity), 0) DESC) AS return_rank
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN RankedReturns rr ON c.c_customer_sk = rr.sr_customer_sk
    GROUP BY c.c_customer_sk, ca.ca_city, ca.ca_state
),
TopCustomers AS (
    SELECT 
        cwr.c_customer_sk,
        cwr.ca_city,
        cwr.ca_state,
        cwr.total_return_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        b.total_net_profit,
        b.total_orders
    FROM CustomersWithReturns cwr
    JOIN CustomerDemographics cd ON cwr.c_customer_sk = cd.cd_demo_sk
    JOIN BaseSales b ON cwr.c_customer_sk = b.ws_ship_customer_sk
    WHERE cwr.return_rank <= 5
),
FinalReport AS (
    SELECT 
        tc.c_customer_sk,
        tc.ca_city,
        tc.ca_state,
        tc.total_return_quantity,
        tc.cd_gender,
        tc.cd_marital_status,
        tc.total_net_profit,
        tc.total_orders,
        CASE 
            WHEN tc.total_return_quantity > 10 THEN 'High Return'
            WHEN tc.total_return_quantity BETWEEN 5 AND 10 THEN 'Medium Return'
            ELSE 'Low Return'
        END AS return_category
    FROM TopCustomers tc
)

SELECT 
    fr.ca_city,
    fr.ca_state,
    COUNT(fr.c_customer_sk) AS num_customers,
    AVG(fr.total_net_profit) AS avg_net_profit,
    SUM(fr.total_return_quantity) AS total_returns,
    STRING_AGG(fr.cd_gender, ',') AS gender_distribution
FROM FinalReport fr
GROUP BY fr.ca_city, fr.ca_state
HAVING SUM(fr.total_return_quantity) > 0 
   AND AVG(fr.total_net_profit) IS NOT NULL
   AND COUNT(fr.c_customer_sk) > 1
ORDER BY total_returns DESC, avg_net_profit DESC;
