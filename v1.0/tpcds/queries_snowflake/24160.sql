
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders_count,
        COUNT(DISTINCT CASE WHEN ws.ws_sales_price > 100 THEN ws.ws_order_number END) AS high_value_web_orders,
        MAX(ws.ws_net_profit) AS max_web_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
RankedCustomers AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY total_web_sales DESC, total_store_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
),
HighValueCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_customer_id,
        rc.total_web_sales,
        rc.total_store_sales,
        rc.web_orders_count,
        rc.store_orders_count,
        rc.high_value_web_orders,
        COALESCE(sm.sm_type, 'Not Specified') AS ship_mode,
        RANK() OVER (PARTITION BY rc.high_value_web_orders ORDER BY rc.total_web_sales DESC) AS high_value_rank
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        ship_mode sm ON rc.sales_rank = (SELECT MAX(sales_rank) FROM RankedCustomers WHERE high_value_web_orders > 0)
)
SELECT 
    hvc.c_customer_id,
    hvc.total_web_sales,
    hvc.total_store_sales,
    hvc.web_orders_count,
    hvc.store_orders_count,
    hvc.high_value_web_orders,
    hvc.ship_mode,
    COALESCE((SELECT AVG(cd.cd_purchase_estimate) FROM customer_demographics cd WHERE cd.cd_demo_sk IN (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = hvc.c_customer_sk)), 0) AS avg_purchase_estimate,
    CASE 
        WHEN hvc.total_web_sales IS NULL THEN 'No Sales'
        WHEN hvc.total_web_sales < 500 THEN 'Low Sales'
        WHEN hvc.total_web_sales BETWEEN 500 AND 1000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    HighValueCustomers hvc
WHERE 
    hvc.high_value_rank <= 10
ORDER BY 
    hvc.total_web_sales DESC, sales_category DESC;
