
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax,
        SUM(sr_net_loss) AS total_net_loss
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),  
CustomerDemographics AS (
    SELECT 
        cd.demo_sk,
        cd.gender,
        CASE 
            WHEN cd_marital_status = 'S' THEN 'Single'
            WHEN cd_marital_status = 'M' THEN 'Married'
            ELSE 'Unknown'
        END AS marital_status,
        cd.education_status,
        cd.purchase_estimate
    FROM 
        customer_demographics cd
), 
WarehouseSales AS (
    SELECT 
        ws.w_warehouse_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.w_warehouse_sk
), 
RankedReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_amt,
        RANK() OVER (ORDER BY cr.total_return_amt DESC) AS return_rank
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
)
SELECT 
    r.first_name,
    r.last_name,
    d.gender,
    d.marital_status,
    d.purchase_estimate,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    COALESCE(s.total_sales, 0) AS total_sales
FROM 
    RankedReturns r
LEFT JOIN 
    CustomerDemographics d ON r.c_customer_sk = d.cd_demo_sk
LEFT JOIN 
    WarehouseSales s ON s.w_warehouse_sk = (
        SELECT 
            w.w_warehouse_sk
        FROM 
            warehouse w
        WHERE 
            w.w_warehouse_sq_ft > 10000
        LIMIT 1
    )
WHERE 
    r.return_rank <= 100
ORDER BY 
    r.total_return_amt DESC;
