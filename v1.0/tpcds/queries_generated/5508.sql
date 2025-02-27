
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20000101 AND 20221231
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        rc.ws_bill_customer_sk,
        rc.total_sales,
        rc.order_count,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        RankedSales rc
    JOIN 
        customer_demographics cd ON rc.ws_bill_customer_sk = cd.cd_demo_sk
    WHERE 
        rc.sales_rank <= 10
),
CustomerAddresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        COUNT(s.s_store_sk) AS store_count
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        store s ON s.s_store_sk = c.c_customer_sk
    GROUP BY 
        ca.ca_address_id, ca.ca_city, ca.ca_state
)
SELECT 
    tc.ws_bill_customer_sk,
    tc.total_sales,
    tc.order_count,
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    ca.store_count
FROM 
    TopCustomers tc
JOIN 
    CustomerAddresses ca ON tc.ws_bill_customer_sk = ca.ca_address_id
ORDER BY 
    tc.total_sales DESC;
