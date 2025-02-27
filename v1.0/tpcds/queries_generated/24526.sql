
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity * sr_return_amt) AS avg_return_value
    FROM store_returns
    GROUP BY sr_customer_sk
), HighValueCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(cr.total_return_amount, 0) > 500 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_segment
    FROM RankedCustomers rc
    LEFT JOIN CustomerReturns cr ON rc.c_customer_sk = cr.sr_customer_sk
), MonthlySales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
), CTE_WithNullLogic AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.customer_segment,
        ms.total_sales,
        CASE 
            WHEN hvc.customer_segment = 'High Value' THEN 'Top Customer'
            WHEN ms.total_sales > 10000 THEN 'Valuable Customer'
            ELSE 'Standard Customer'
        END AS customer_category
    FROM HighValueCustomers hvc
    LEFT JOIN MonthlySales ms ON hvc.c_customer_sk IS NULL OR hvc.c_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL)
)
SELECT 
    c.*,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS return_rank,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') 
        FILTER (WHERE customer_category = 'Top Customer') AS top_customers_list
FROM CTE_WithNullLogic c
WHERE c.total_sales IS NULL OR c.customer_segment = 'High Value'
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, c.customer_segment, c.total_sales, c.customer_category
ORDER BY return_rank;
