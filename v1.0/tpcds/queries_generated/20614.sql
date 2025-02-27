
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        COUNT(*) AS total_sales,
        SUM(ws_sales_price) AS total_revenue,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
), RankedSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales,
        rs.total_revenue,
        rs.total_profit,
        ROW_NUMBER() OVER (ORDER BY rs.total_profit DESC, rs.total_sales ASC) as rank
    FROM 
        RecursiveSales rs
), CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity,
        AVG(sr_return_tax) AS avg_return_tax,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY COUNT(*) DESC) AS return_rank
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_customer_sk
), DetailedCustomer AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.avg_return_tax, 0) AS avg_return_tax,
        rs.total_sales,
        rs.total_revenue
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_item_sk
), FinalResults AS (
    SELECT 
        *,
        CASE 
            WHEN return_count > 10 THEN 'Frequent Returner'
            WHEN total_revenue > 1000 THEN 'High Value Customer'
            WHEN total_profit < 0 THEN 'Loss Incurring'
            ELSE 'Regular Customer'
        END AS customer_category
    FROM 
        DetailedCustomer
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.return_count,
    c.total_return_amount,
    c.avg_return_tax,
    c.total_sales,
    c.total_revenue,
    c.customer_category,
    CASE 
        WHEN c.total_revenue IS NULL THEN 'No Revenue'
        WHEN c.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Data Available'
    END AS sales_status
FROM 
    FinalResults c
WHERE 
    c.total_sales > 0 OR c.return_count IS NOT NULL
ORDER BY 
    c.total_revenue DESC, c.return_count ASC
LIMIT 50;
