
WITH RECURSIVE SalesRank AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid) AS total_spent,
        RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01') 
                              AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-31')
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) AS max_sale_price
    FROM 
        web_sales ws
    JOIN 
        CustomerDemographics c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_id
)
SELECT 
    s.customer_sk,
    d.cd_gender,
    s.total_spent,
    s.total_orders,
    s.total_sales,
    s.max_sale_price,
    CASE 
        WHEN s.total_spent > 1000 THEN 'High Value'
        WHEN s.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM 
    SalesRank s
JOIN 
    CustomerDemographics d ON s.customer_sk = d.c_customer_sk
JOIN 
    SalesSummary ss ON d.c_customer_id = ss.c_customer_id
WHERE 
    s.sales_rank <= 20
ORDER BY 
    total_spent DESC;
