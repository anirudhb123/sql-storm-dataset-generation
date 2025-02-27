
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS num_returns
    FROM 
        store_returns sr
    JOIN 
        customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_returned_quantity,
        total_returned_amount,
        num_returns,
        RANK() OVER (ORDER BY total_returned_amount DESC) AS rank
    FROM 
        CustomerReturns
)
SELECT 
    t.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    w.w_warehouse_name,
    SUM(ws.ws_ext_sales_price) AS total_sales
FROM 
    TopCustomers t
JOIN 
    customer_demographics cd ON t.c_customer_id = cd.cd_demo_sk
JOIN 
    web_sales ws ON t.c_customer_id = ws.ws_bill_customer_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.warehouse_sk
WHERE 
    t.rank <= 10
GROUP BY 
    t.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate, w.warehouse_name
ORDER BY 
    total_sales DESC;
