
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.ship_date_sk,
        ws.sold_date_sk,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.net_profit DESC) AS rn
    FROM web_sales ws
    WHERE ws.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'UNKNOWN'
            ELSE cd.cd_credit_rating 
        END AS credit_rating
    FROM customer_demographics cd
    WHERE cd.cd_marital_status IN ('M', 'S')
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY ca.ca_city) AS city_rank
    FROM customer_address ca
    WHERE ca.ca_state IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        COUNT(*) AS return_count
    FROM store_returns sr
    GROUP BY sr.sr_customer_sk
),
FinalSelection AS (
    SELECT 
        cust.c_customer_id,
        CASE 
            WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Other'
        END AS Gender,
        SUM(ws.net_profit) AS total_profit,
        COALESCE(returns.total_returns, 0) AS total_returns,
        COUNT(DISTINCT addr.ca_address_sk) AS unique_addresses,
        MAX(RankSales.rn) AS highest_rank
    FROM customer cust
    JOIN CustomerDemographics cd ON cust.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON cust.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN CustomerReturns returns ON cust.c_customer_sk = returns.sr_customer_sk
    LEFT JOIN CustomerAddresses addr ON cust.c_current_addr_sk = addr.ca_address_sk
    LEFT JOIN RankedSales ON cust.c_customer_sk = RankedSales.bill_customer_sk
    GROUP BY cust.c_customer_id, cd.cd_gender
    HAVING SUM(ws.net_profit) > (SELECT AVG(net_profit) FROM web_sales WHERE net_profit IS NOT NULL)
)

SELECT 
    f.c_customer_id,
    f.Gender,
    f.total_profit,
    f.total_returns,
    CASE
        WHEN f.total_returns = 0 THEN 'No Returns'
        WHEN f.total_returns > 5 THEN 'Frequent Returner'
        ELSE 'Occasional Returner'
    END AS return_label,
    (CASE 
        WHEN f.highest_rank IS NULL THEN 'No Sales Ranking'
        ELSE CAST(f.highest_rank AS VARCHAR)
    END) AS sales_rank_status
FROM FinalSelection f
WHERE f.total_profit > 1000
ORDER BY f.total_profit DESC, f.Gender;
