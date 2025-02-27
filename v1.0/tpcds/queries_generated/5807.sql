
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_ship_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws_bill_customer_sk, ws_ship_date_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
TopCustomers AS (
    SELECT 
        rd.ws_bill_customer_sk,
        cc.c_first_name,
        cc.c_last_name,
        rd.total_quantity,
        rd.total_revenue
    FROM 
        RankedSales rd
    JOIN 
        CustomerDetails cc ON rd.ws_bill_customer_sk = cc.c_customer_sk
    WHERE 
        rd.sales_rank <= 5
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_quantity,
    tc.total_revenue,
    d.d_date
FROM 
    TopCustomers tc
JOIN 
    date_dim d ON tc.ws_ship_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
ORDER BY 
    tc.total_revenue DESC;
