
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_return_quantity,
        COUNT(DISTINCT sr_ticket_number) AS total_return_tickets
    FROM 
        customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        (
            SELECT COUNT(*)
            FROM customer_demographics 
            WHERE cd_purchase_estimate > 5000 AND cd_marital_status = 'M'
        ) AS higher_purchasing_customers
    FROM 
        customer_demographics cd
),
SalesStats AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_moy = 3
        )
    GROUP BY ws.ws_bill_customer_sk
),
RankedSales AS (
    SELECT 
        customer_sk,
        total_sales,
        total_orders,
        avg_discount,
        ROW_NUMBER() OVER (PARTITION BY customer_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesStats
)
SELECT 
    cr.c_first_name,
    cr.c_last_name,
    cr.total_return_quantity,
    COALESCE(ds.total_sales, 0) AS total_sales,
    CASE 
        WHEN cr.total_return_quantity > 0 THEN 
            ROUND(100.0 * (ds.total_sales / NULLIF(cr.total_return_quantity, 0)), 2)
        ELSE 
            0 
    END AS return_to_sales_ratio,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.higher_purchasing_customers
FROM 
    CustomerReturns cr
LEFT JOIN RankedSales ds ON cr.c_customer_sk = ds.customer_sk
JOIN CustomerDemographics cd ON cd.cd_demo_sk = (
    SELECT c.c_current_cdemo_sk 
    FROM customer c 
    WHERE c.c_customer_sk = cr.c_customer_sk
)
WHERE 
    cr.total_return_quantity > 0
ORDER BY 
    return_to_sales_ratio DESC;
