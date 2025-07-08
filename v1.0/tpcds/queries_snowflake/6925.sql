
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amount,
        SUM(sr.sr_return_quantity) AS total_returned_quantity
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_purchase_estimate > 1000
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_quantity) AS total_items_sold
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedStats AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate,
        cs.total_returns,
        cs.total_returned_amount,
        cs.total_returned_quantity,
        ss.total_sales,
        ss.total_items_sold
    FROM 
        CustomerStats cs
    LEFT JOIN 
        SalesStats ss ON cs.c_customer_id = ss.ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_purchase_estimate,
    COALESCE(total_returns, 0) AS total_returns,
    COALESCE(total_returned_amount, 0) AS total_returned_amount,
    COALESCE(total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_items_sold, 0) AS total_items_sold
FROM 
    CombinedStats c
ORDER BY 
    total_sales DESC
LIMIT 10;
