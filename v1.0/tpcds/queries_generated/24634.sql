
WITH RECURSIVE SalesAnalysis AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS cumulative_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 10000
),
CustomerAnalysis AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COALESCE(SUM(ws_ext_sales_price), 0) AS total_spent
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name, cd_gender, cd_marital_status, cd_education_status
),
TopCustomers AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM 
        CustomerAnalysis c
    WHERE 
        total_spent > (SELECT AVG(total_spent) FROM CustomerAnalysis)
),
ReturnedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_sales,
        (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_order_number = ws.ws_order_number) AS returns_count
    FROM 
        web_sales ws
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    GROUP BY 
        ws.ws_order_number, ws.ws_item_sk
),
FinalReport AS (
    SELECT 
        tc.customer_rank,
        tc.c_first_name,
        tc.c_last_name,
        sa.rn AS order_sequence,
        ra.total_sales,
        ra.returns_count,
        CASE 
            WHEN ra.returns_count > 0 THEN 'Returned'
            ELSE 'All Sales'
        END AS sale_status
    FROM 
        TopCustomers tc
    JOIN SalesAnalysis sa ON tc.customer_rank = sa.rn
    LEFT JOIN ReturnedSales ra ON sa.ws_order_number = ra.ws_order_number
)
SELECT 
    *, 
    CONCAT(c_first_name, ' ', c_last_name) AS full_customer_name,
    CASE 
        WHEN sale_status = 'Returned' AND total_sales < 100 THEN 'Needs Attention'
        WHEN sale_status = 'All Sales' AND total_sales >= 1000 THEN 'VIP Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    FinalReport
ORDER BY 
    customer_rank ASC, order_sequence DESC;
