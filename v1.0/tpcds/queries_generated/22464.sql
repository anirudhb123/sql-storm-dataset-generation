
WITH RecursiveCustomerSales AS (
    SELECT 
        c.c_customer_sk, 
        c.c_customer_id, 
        SUM(ws.ws_net_paid) AS total_sales, 
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank 
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
SalesDetails AS (
    SELECT 
        cs.cs_customer_sk, 
        cs.total_sales, 
        coalesce(ws.ws_quantity, 0) AS total_quantity,
        p.p_discount_active
    FROM 
        RecursiveCustomerSales cs 
    LEFT JOIN 
        web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk 
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk 
    WHERE 
        cs.sales_rank = 1 OR cs.total_sales IS NULL
),
FinalReport AS (
    SELECT 
        s.s_store_sk, 
        s.s_store_name, 
        SUM(sd.total_sales) AS store_sales_total,
        COUNT(DISTINCT sd.c_customer_id) AS unique_customers,
        CASE 
            WHEN SUM(sd.total_sales) IS NULL THEN 'No Sales' 
            ELSE 'Sales Recorded' 
        END AS sales_status
    FROM 
        store s 
    LEFT JOIN 
        SalesDetails sd ON s.s_store_sk = sd.cs_customer_sk 
    GROUP BY 
        s.s_store_sk, s.s_store_name
)
SELECT 
    f.s_store_sk, 
    f.s_store_name, 
    f.store_sales_total, 
    f.unique_customers, 
    f.sales_status,
    (SELECT COUNT(*) FROM customer c WHERE c.c_birth_month IS NULL OR c.c_birth_month BETWEEN 1 AND 6) AS customers_born_first_half_year,
    (SELECT SUM(ws_net_profit) FROM web_sales WHERE ws_net_profit > (SELECT AVG(ws_net_profit) FROM web_sales)) AS above_avg_profit
FROM 
    FinalReport f
ORDER BY 
    f.store_sales_total DESC NULLS LAST;
