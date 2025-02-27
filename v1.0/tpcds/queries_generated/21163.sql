
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL 
        AND cd.cd_marital_status IN ('M', 'S') 
        AND ws.ws_sold_date_sk BETWEEN 1 AND 365 -- First year of data
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_sales_price) IS NOT NULL
),
TopCustomers AS (
    SELECT 
        customer_id,
        total_sales,
        order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    COALESCE((
        SELECT 
            ROUND(AVG(sr_return_amt), 2)
        FROM 
            store_returns sr
        WHERE 
            sr.sr_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = tc.customer_id)
    ), 0) AS avg_return_amount,
    CASE 
        WHEN tc.total_sales > 1000 THEN 'High Spender'
        WHEN tc.total_sales BETWEEN 500 AND 1000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM 
    TopCustomers tc
LEFT JOIN 
    income_band ib ON (tc.total_sales BETWEEN ib.lower_bound AND ib.upper_bound)
ORDER BY 
    total_sales DESC;
