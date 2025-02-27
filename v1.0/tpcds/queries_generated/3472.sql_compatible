
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rn 
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
), 
HighValueReturns AS (
    SELECT 
        r.rn,
        r.total_returns,
        r.total_return_amt,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_birth_country,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        RankedReturns r
    JOIN 
        customer c ON r.sr_customer_sk = c.c_customer_sk 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    WHERE 
        r.total_return_amt > (SELECT AVG(total_return_amt) FROM RankedReturns)
    ORDER BY 
        r.total_return_amt DESC
)
SELECT 
    hvr.full_name,
    hvr.total_returns,
    hvr.total_return_amt,
    COALESCE(cd.cd_gender, 'Not Specified') AS gender,
    COALESCE(cd.cd_marital_status, 'Not Specified') AS marital_status,
    (SELECT COUNT(DISTINCT cs_order_number) FROM catalog_sales WHERE cs_bill_customer_sk = hvr.sr_customer_sk) AS total_catalog_orders,
    (SELECT STRING_AGG(DISTINCT w.w_warehouse_name, ', ') 
     FROM inventory i 
     JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk 
     WHERE i.inv_item_sk IN (SELECT sr_item_sk FROM store_returns WHERE sr_customer_sk = hvr.sr_customer_sk)) AS warehouses_used
FROM 
    HighValueReturns hvr
WHERE 
    hvr.rn <= 10
ORDER BY 
    hvr.total_return_amt DESC;
