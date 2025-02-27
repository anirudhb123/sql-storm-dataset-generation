
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk, 
        wr_item_sk, 
        wr_return_quantity, 
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY wr_return_quantity DESC) as rn
    FROM 
        web_returns
    WHERE 
        wr_return_quantity IS NOT NULL
),
TopReturns AS (
    SELECT 
        wr_returning_customer_sk, 
        SUM(wr_return_quantity) AS total_returned
    FROM 
        RankedReturns
    WHERE 
        rn <= 3
    GROUP BY 
        wr_returning_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Not Specified') AS gender,
        COALESCE(cd.cd_marital_status, 'Not Specified') AS marital_status,
        COALESCE(cd.cd_education_status, 'Not Specified') AS education_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 0 
            ELSE cd.cd_purchase_estimate 
        END AS purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesDetails AS (
    SELECT 
        COALESCE(ws_bill_customer_sk, cs_bill_customer_sk, ss_customer_sk) AS customer_sk,
        SUM(COALESCE(ws_net_paid, cs_net_paid, ss_net_paid)) AS total_spent,
        COUNT(DISTINCT COALESCE(ws_order_number, cs_order_number, ss_ticket_number)) AS total_orders
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    GROUP BY 
        COALESCE(ws_bill_customer_sk, cs_bill_customer_sk, ss_customer_sk)
)
SELECT 
    cd.gender,
    cd.marital_status,
    cd.education_status,
    SUM(sd.total_spent) AS total_spent,
    COUNT(sd.total_orders) AS total_orders,
    rt.total_returned
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesDetails sd ON cd.c_customer_sk = sd.customer_sk
LEFT JOIN 
    TopReturns rt ON cd.c_customer_sk = rt.wr_returning_customer_sk
WHERE 
    cd.gender = 'M'
GROUP BY 
    cd.gender, cd.marital_status, cd.education_status, rt.total_returned
HAVING 
    SUM(sd.total_spent) > 1000 OR rt.total_returned IS NOT NULL
ORDER BY 
    total_spent DESC, rt.total_returned DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
