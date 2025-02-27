
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.web_site_id) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 100
),
CustomerPreferences AS (
    SELECT 
        c.c_customer_id,
        CASE 
            WHEN cd.cd_gender = 'F' THEN 'Female'
            WHEN cd.cd_gender = 'M' THEN 'Male'
            ELSE 'Unknown'
        END AS gender,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_spent,
        (SELECT COUNT(DISTINCT ws.ws_order_number) 
         FROM web_sales ws 
         WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender
),
AggregatedReturns AS (
    SELECT 
        sr.refunded_customer_sk,
        SUM(sr_return_qty) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns sr 
    GROUP BY 
        sr.refunded_customer_sk
)
SELECT 
    cp.c_customer_id,
    cp.gender,
    cp.total_spent,
    cp.order_count,
    COALESCE(ar.total_returns, 0) AS total_returns,
    COALESCE(ar.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN cp.total_spent > 500 THEN 'High Value'
        WHEN cp.total_spent BETWEEN 100 AND 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    CASE 
        WHEN rw.sales_rank <= 10 THEN 'Top Sales'
        ELSE 'Other Sales'
    END AS sales_category
FROM 
    CustomerPreferences cp
LEFT JOIN 
    AggregatedReturns ar ON cp.c_customer_id = ar.refunded_customer_sk
LEFT JOIN 
    RankedSales rw ON cp.order_count = rw.ws_order_number
WHERE 
    ar.total_return_amt IS NULL OR ar.total_return_amt < 100
ORDER BY 
    cp.total_spent DESC, cp.c_customer_id ASC;

```
