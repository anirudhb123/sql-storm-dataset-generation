
WITH RECURSIVE SalesTrend AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (ORDER BY d.d_date) AS row_num
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count,
        COALESCE(SUM(cr.total_returned), 0) AS total_returned
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    customer_count,
    total_returned,
    AVG(total_profit) OVER (PARTITION BY cd_gender) AS avg_profit_by_gender,
    MAX(total_quantity) OVER (PARTITION BY cd_marital_status) AS max_quantity_by_marital_status
FROM 
    CustomerDemographics
INNER JOIN 
    SalesTrend ON TRUE
WHERE 
    total_returned < (SELECT AVG(total_returned) FROM CustomerReturns)
ORDER BY 
    cd_gender ASC, customer_count DESC
LIMIT 100;
