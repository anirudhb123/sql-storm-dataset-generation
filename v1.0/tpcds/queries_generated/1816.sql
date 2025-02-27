
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_quantity) AS avg_quantity_per_order
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count,
        COALESCE(ss.avg_quantity_per_order, 0) AS avg_quantity_per_order
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        SalesSummary ss ON c.c_customer_sk = ss.customer_sk
),
RankedCustomers AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank,
        RANK() OVER (PARTITION BY cd_marital_status ORDER BY total_return_amount DESC) AS return_rank
    FROM
        CustomerInfo
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c_gender,
    return_count,
    total_return_amount,
    total_sales,
    order_count,
    avg_quantity_per_order,
    sales_rank,
    return_rank
FROM 
    RankedCustomers c
WHERE 
    (sales_rank <= 5 OR return_rank <= 5) 
    AND (total_sales > 1000 OR return_count > 3)
ORDER BY 
    cd_gender, total_sales DESC, return_rank;
