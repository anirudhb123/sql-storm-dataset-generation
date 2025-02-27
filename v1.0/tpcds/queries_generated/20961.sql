
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
        AND (cd.cd_gender = 'M' OR cd.cd_gender = 'F')
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        ss.total_profit,
        ss.order_count,
        ss.total_quantity
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        SalesSummary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        rc.purchase_rank <= 3
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_profit, 0) AS total_profit,
    COALESCE(tc.order_count, 0) AS order_count,
    COALESCE(tc.total_quantity, 0) AS total_quantity,
    CASE 
        WHEN tc.total_profit > 1000 THEN 'High Value'
        WHEN tc.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    (SELECT 
        COUNT(DISTINCT wr.returned_time_sk) 
     FROM 
        web_returns wr 
     WHERE 
        wr.returning_customer_sk = tc.c_customer_sk 
        AND wr.return_quantity IS NOT NULL
    ) AS return_count
FROM 
    TopCustomers tc
ORDER BY 
    tc.total_profit DESC, tc.c_last_name ASC
LIMIT 10;
