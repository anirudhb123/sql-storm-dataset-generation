
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
RecentReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        sr_customer_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
    hv.total_orders,
    hv.total_spent,
    rs.total_quantity,
    rs.total_sales
FROM 
    customer c
LEFT JOIN 
    RecentReturns r ON c.c_customer_sk = r.sr_customer_sk
LEFT JOIN 
    HighValueCustomers hv ON c.c_customer_sk = hv.c_customer_sk
LEFT JOIN 
    RankedSales rs ON rs.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
WHERE 
    c.c_birth_year < (EXTRACT(YEAR FROM CURRENT_DATE) - 30) -- Filtering customers who are older than 30
ORDER BY 
    hv.total_spent DESC NULLS LAST, r.total_returns DESC;

