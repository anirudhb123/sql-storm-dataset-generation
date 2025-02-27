
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS orders_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.orders_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_sales > 1000
),
StateSales AS (
    SELECT 
        ca.ca_state,
        SUM(ws.ws_ext_sales_price) AS state_sales
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.ca_state
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cs.total_sales) AS total_sales_by_gender
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerSales cs ON cs.c_customer_id = c.c_customer_id
    GROUP BY 
        cd.cd_gender
)

SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.orders_count,
    ss.state_sales,
    cd.cd_gender,
    cd.avg_purchase_estimate,
    cd.total_sales_by_gender
FROM 
    TopCustomers tc
JOIN 
    StateSales ss ON ss.state_sales > 50000
JOIN 
    CustomerDemographics cd ON cd.total_sales_by_gender > 100000
ORDER BY 
    tc.sales_rank, ss.state_sales DESC;
