
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
AverageSales AS (
    SELECT 
        AVG(total_sales) AS avg_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws_ext_sales_price) AS customer_sales,
        cd_marital_status,
        cd_gender,
        cd_buy_potential
    FROM 
        customer c
    JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.ws_sales_price > 100
    GROUP BY 
        c.c_customer_id, 
        cd_marital_status, 
        cd_gender, 
        cd_buy_potential
    HAVING 
        SUM(ws_ext_sales_price) > (SELECT avg_sales FROM AverageSales)
),
FinalSelection AS (
    SELECT 
        tc.c_customer_id,
        tc.customer_sales,
        tc.cd_marital_status,
        tc.cd_gender,
        tc.cd_buy_potential,
        ca.ca_city,
        ca.ca_state,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        TopCustomers tc
    LEFT JOIN 
        customer_address ca ON ca.ca_address_sk = (
            SELECT c_current_addr_sk FROM customer WHERE c_customer_id = tc.c_customer_id
        )
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = tc.c_customer_id
    GROUP BY 
        tc.c_customer_id, 
        tc.customer_sales, 
        tc.cd_marital_status, 
        tc.cd_gender, 
        tc.cd_buy_potential, 
        ca.ca_city, 
        ca.ca_state
)
SELECT 
    f.c_customer_id,
    f.customer_sales,
    f.cd_marital_status,
    f.cd_gender,
    f.cd_buy_potential,
    f.ca_city,
    f.ca_state,
    f.order_count,
    CASE 
        WHEN f.order_count IS NULL THEN 'No orders'
        WHEN f.order_count > 5 THEN 'Frequent buyer'
        ELSE 'Occasional buyer'
    END AS buyer_type
FROM 
    FinalSelection f
ORDER BY 
    f.customer_sales DESC
LIMIT 100;
