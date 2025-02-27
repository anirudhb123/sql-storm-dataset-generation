
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        ca.state AS customer_state,
        cd.cd_gender,
        COUNT(DISTINCT r.r_reason_sk) AS total_return_reasons
    FROM 
        customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk 
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE 
        c.c_customer_sk IN (SELECT ws_bill_customer_sk FROM RankedSales WHERE sales_rank <= 10)
    GROUP BY 
        ca.state, cd.cd_gender
)
SELECT 
    customer_state,
    cd_gender,
    AVG(total_return_reasons) AS avg_return_reasons
FROM 
    TopCustomers
GROUP BY 
    customer_state, cd_gender
ORDER BY 
    customer_state, cd_gender;
