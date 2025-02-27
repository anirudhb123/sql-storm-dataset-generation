
WITH RankedReturns AS (
    SELECT 
        COALESCE(sr.returned_date_sk, cr.returned_date_sk) AS return_date_sk,
        COALESCE(sr.returning_customer_sk, cr.returning_customer_sk) AS returning_customer_sk,
        COALESCE(sr.return_quantity, cr.return_quantity) AS return_quantity,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(sr.returned_date_sk, cr.returned_date_sk) ORDER BY COALESCE(sr.return_quantity, cr.return_quantity) DESC) AS rn
    FROM 
        store_returns sr
    FULL OUTER JOIN 
        catalog_returns cr ON sr.cr_item_sk = cr.cr_item_sk AND sr.cr_order_number = cr.cr_order_number
    WHERE 
        COALESCE(sr.return_quantity, cr.return_quantity) IS NOT NULL
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
    HAVING 
        COUNT(DISTINCT c.c_customer_id) > 1
),
ReturnStatistics AS (
    SELECT 
        r.return_date_sk,
        SUM(r.return_quantity) AS total_returned,
        AVG(r.return_quantity) AS avg_return_quantity,
        MAX(r.return_quantity) AS max_return_quantity
    FROM 
        RankedReturns r
    WHERE 
        r.rn <= 5
    GROUP BY 
        r.return_date_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        COUNT(ws.ws_order_number) AS total_sales
    FROM 
        web_sales ws
    INNER JOIN 
        CustomerDemographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT return_date_sk FROM ReturnStatistics)
    GROUP BY 
        ws.ws_sold_date_sk
)
SELECT 
    d.d_date, 
    COALESCE(s.total_sales, 0) AS total_sales, 
    COALESCE(s.total_profit, 0) AS total_profit, 
    COALESCE(s.avg_net_paid, 0) AS avg_net_paid, 
    COALESCE(r.total_returned, 0) AS total_returned,
    r.avg_return_quantity,
    r.max_return_quantity
FROM 
    date_dim d
LEFT JOIN 
    SalesData s ON d.d_date_sk = s.ws_sold_date_sk
LEFT JOIN 
    ReturnStatistics r ON d.d_date_sk = r.return_date_sk
WHERE 
    d.d_date BETWEEN '2020-01-01' AND '2023-12-31'
    AND (r.max_return_quantity > (SELECT AVG(total_returned) FROM ReturnStatistics) OR r.max_return_quantity IS NULL)
ORDER BY 
    d.d_date;
