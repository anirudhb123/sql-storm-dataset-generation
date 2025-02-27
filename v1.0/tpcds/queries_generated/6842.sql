
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS web_order_count,
        COUNT(DISTINCT CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_order_number END) AS catalog_order_count,
        COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number END) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_sales,
        web_order_count,
        catalog_order_count,
        store_order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales
)
SELECT 
    t.c_customer_id,
    t.total_sales,
    t.web_order_count,
    t.catalog_order_count,
    t.store_order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ca.ca_city,
    ca.ca_state
FROM 
    TopCustomers t
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = t.c_customer_id)
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_id = t.c_customer_id)
WHERE 
    t.sales_rank <= 10
ORDER BY 
    t.total_sales DESC;
