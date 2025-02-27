
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
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
        ss.total_sales,
        ss.average_profit,
        ss.order_count
    FROM 
        RankedCustomers rc
    JOIN 
        SalesSummary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        rc.rank <= 5
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    ss.total_sales,
    ss.average_profit,
    COALESCE(ss.order_count, 0) AS order_count,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        WHEN ss.total_sales < 500 THEN 'Low Sales'
        WHEN ss.total_sales BETWEEN 500 AND 1500 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    TopCustomers ss
JOIN 
    customer c ON ss.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk AND s.ss_sold_date_sk = (
        SELECT MAX(ss_sold_date_sk) 
        FROM store_sales 
        WHERE ss_customer_sk = c.c_customer_sk
    )
WHERE 
    c.c_preferred_cust_flag = 'Y'
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
