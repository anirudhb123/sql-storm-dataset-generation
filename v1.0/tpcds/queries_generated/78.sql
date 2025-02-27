
WITH CustomerPurchaseData AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_in_gender
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), TopCustomers AS (
    SELECT 
        customer_id,
        c_first_name,
        c_last_name,
        total_spent,
        order_count,
        rank_in_gender
    FROM 
        CustomerPurchaseData
    WHERE 
        rank_in_gender <= 10
)
SELECT 
    tc.customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.order_count,
    CASE 
        WHEN TRIM(tc.c_last_name) IS NULL THEN 'Unknown'
        ELSE tc.c_last_name
    END AS clean_last_name,
    COALESCE(tb.return_count, 0) AS return_count,
    COALESCE(tb.returned_amount, 0.00) AS returned_amount
FROM 
    TopCustomers tc
LEFT JOIN (
    SELECT 
        wr_refunded_customer_sk,
        COUNT(wr_order_number) AS return_count,
        SUM(wr_return_amt) AS returned_amount
    FROM 
        web_returns
    GROUP BY 
        wr_refunded_customer_sk
) tb ON tc.customer_id = tb.wr_refunded_customer_sk
ORDER BY 
    tc.total_spent DESC;
