
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales IS NOT NULL
),
Promotions AS (
    SELECT 
        p.p_promo_id,
        COUNT(cs.c_customer_sk) AS customer_count
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    JOIN 
        TopCustomers tc ON ws.ws_bill_customer_sk = tc.c_customer_sk
    GROUP BY 
        p.p_promo_id
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    pc.customer_count,
    STRING_AGG(DISTINCT p.p_promo_id, ', ') AS promo_ids
FROM 
    TopCustomers tc
LEFT JOIN 
    Promotions pc ON tc.c_customer_sk = pc.promo_id
LEFT JOIN 
    promotion p ON pc.promo_id = p.p_promo_id
WHERE 
    tc.sales_rank <= 10
GROUP BY 
    tc.c_first_name, tc.c_last_name, pc.customer_count
ORDER BY 
    total_sales DESC;
