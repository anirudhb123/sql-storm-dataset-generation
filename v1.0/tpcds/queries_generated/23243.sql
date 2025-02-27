
WITH RankedReturns AS (
    SELECT 
        cr.returning_customer_sk,
        cr.returning_cdemo_sk,
        cr.returning_hdemo_sk,
        cr.returning_addr_sk,
        SUM(cr.return_quantity) AS total_return_quantity,
        SUM(cr_return_amount) AS total_return_amount,
        DENSE_RANK() OVER(PARTITION BY cr.returning_customer_sk ORDER BY SUM(cr.return_quantity) DESC) AS rnk
    FROM 
        catalog_returns cr
    LEFT JOIN 
        customer c ON cr.returning_customer_sk = c.c_customer_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        cr.returning_customer_sk, 
        cr.returning_cdemo_sk, 
        cr.returning_hdemo_sk, 
        cr.returning_addr_sk
),
AggregatedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        AVG(ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                           AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(re.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(re.total_return_amount, 0) AS total_return_amount,
    COALESCE(asales.total_sales_quantity, 0) AS total_sales_quantity,
    asales.avg_net_paid,
    asales.order_count,
    CASE 
        WHEN COALESCE(asales.total_sales_quantity, 0) > 0 THEN 
            CASE 
                WHEN COALESCE(re.total_return_quantity, 0) / COALESCE(asales.total_sales_quantity, 0) > 0.1 THEN 'High Return'
                ELSE 'Normal Return'
            END
        ELSE 'No Sales'
    END AS return_category
FROM 
    customer c
LEFT JOIN 
    RankedReturns re ON re.returning_customer_sk = c.c_customer_sk
LEFT JOIN 
    AggregatedSales asales ON asales.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    (c.c_birth_year IS NULL OR c.c_birth_year < 1990)
    AND (c.c_email_address LIKE '%@example.com' OR c.c_first_name IS NULL)
ORDER BY 
    return_category, 
    total_return_amount DESC
LIMIT 100;
