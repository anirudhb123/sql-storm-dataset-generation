
WITH RankedReturns AS (
    SELECT 
        wr_item_sk,
        wr_return_quantity,
        wr_order_number,
        ROW_NUMBER() OVER (PARTITION BY wr_item_sk ORDER BY wr_returned_date_sk DESC) AS rnk
    FROM 
        web_returns
    WHERE 
        wr_return_quantity > 0
),
ExtendedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL AND 
        (cd.cd_marital_status = 'S' OR cd.cd_marital_status IS NULL)
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    COALESCE(er.total_sold, 0) AS total_sold,
    COALESCE(er.order_count, 0) AS order_count,
    COALESCE(er.avg_sales_price, 0) AS avg_sales_price,
    COALESCE(rr.wr_return_quantity, 0) AS return_quantity,
    CASE 
        WHEN rr.rnk = 1 THEN 'Most Recent'
        ELSE 'Older Return'
    END AS return_category
FROM 
    CustomerInfo ci
LEFT JOIN 
    ExtendedSales er ON er.ws_item_sk IN (SELECT DISTINCT wr_item_sk FROM RankedReturns rr WHERE rr.rnk = 1) -- correlated subquery
LEFT JOIN 
    RankedReturns rr ON rr.wr_returning_customer_sk = ci.c_customer_sk AND rr.wr_return_quantity > 0
WHERE 
    ci.cd_credit_rating IN (SELECT DISTINCT cd_credit_rating FROM customer_demographics WHERE cd_purchase_estimate > 500) -- obscure filter
ORDER BY 
    total_sold DESC, 
    return_quantity ASC 
LIMIT 50;
