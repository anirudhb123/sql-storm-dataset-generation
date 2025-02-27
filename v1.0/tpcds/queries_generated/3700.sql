
WITH SalesData AS (
    SELECT 
        w.warehouse_name,
        SUM(ws.net_paid) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS order_count,
        AVG(ws.net_profit) AS avg_profit,
        ROW_NUMBER() OVER (PARTITION BY w.warehouse_name ORDER BY SUM(ws.net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.warehouse_sk = w.warehouse_sk
    WHERE 
        ws.sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        w.warehouse_name
), CustomerInfo AS (
    SELECT 
        c.customer_id,
        cd.demo_sk,
        cd.gender,
        cd.marital_status,
        dd.year AS purchase_year,
        DENSE_RANK() OVER (PARTITION BY cd.gender ORDER BY cd.purchase_estimate DESC) AS income_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    JOIN 
        date_dim dd ON c.first_sales_date_sk = dd.date_sk
), ReturnStats AS (
    SELECT 
        sr.store_sk,
        COUNT(sr.returned_date_sk) AS total_returns,
        SUM(sr.return_amt) AS total_return_amt,
        AVG(sr.return_tax) AS avg_return_tax
    FROM 
        store_returns sr
    GROUP BY 
        sr.store_sk
)

SELECT 
    si.warehouse_name,
    coalesce(cs.total_sales, 0) AS total_sales,
    coalesce(cs.order_count, 0) AS order_count,
    COALESCE(cs.avg_profit, 0) AS avg_profit,
    cr.total_returns,
    cr.total_return_amt,
    cr.avg_return_tax,
    ci.gender,
    ci.marital_status 
FROM 
    SalesData cs
FULL OUTER JOIN 
    ReturnStats cr ON cs.warehouse_name = cr.store_sk
FULL OUTER JOIN 
    CustomerInfo ci ON ci.income_rank < 10 
WHERE 
    (cs.total_sales > 10000 OR cr.total_returns > 50)
    AND (ci.gender IS NOT NULL OR ci.marital_status IS NOT NULL)
ORDER BY 
    total_sales DESC, order_count DESC;
