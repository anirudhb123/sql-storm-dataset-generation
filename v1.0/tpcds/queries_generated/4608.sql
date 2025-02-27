
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
HighReturnCustomers AS (
    SELECT 
        rr.sr_customer_sk,
        rr.total_returns,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        RankedReturns rr
    JOIN 
        customer cd ON rr.sr_customer_sk = cd.c_customer_sk
    LEFT JOIN 
        customer_address ca ON cd.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        rr.rank <= 10
    GROUP BY 
        rr.sr_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, ca.ca_city
), 
AggregateData AS (
    SELECT 
        COUNT(*) AS num_customers,
        AVG(total_returns) AS avg_returns,
        AVG(total_spent) AS avg_spent
    FROM 
        HighReturnCustomers
)
SELECT 
    hrc.ca_city,
    hrc.cd_gender,
    hrc.cd_marital_status,
    hrc.total_returns,
    hrc.total_spent,
    ad.num_customers,
    ad.avg_returns,
    ad.avg_spent
FROM 
    HighReturnCustomers hrc
CROSS JOIN 
    AggregateData ad
ORDER BY 
    hrc.total_returns DESC, hrc.total_spent DESC
LIMIT 50;
