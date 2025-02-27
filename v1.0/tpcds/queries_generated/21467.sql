
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_paid) DESC) AS rnk
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_quantity,
        cs.order_count,
        cs.total_net_paid,
        RANK() OVER (ORDER BY cs.total_net_paid DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_net_paid IS NOT NULL
),
PromotionsSummary AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count,
        SUM(cs.total_net_paid) AS promo_revenue
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    LEFT JOIN 
        CustomerSales cs ON ws.ws_bill_customer_sk = cs.c_customer_id
    GROUP BY 
        p.p_promo_id
),
StoreSalesSummary AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_net_paid) AS total_sales,
        AVG(ss.ss_list_price) AS avg_list_price
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        s.s_store_id
)
SELECT 
    tc.c_customer_id, 
    tc.total_quantity, 
    tc.order_count, 
    ps.promo_revenue,
    COALESCE(ss.total_sales, 0) AS store_total_sales,
    CASE 
        WHEN tc.rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    TopCustomers tc
LEFT JOIN 
    PromotionsSummary ps ON ps.customer_count > 5
LEFT JOIN 
    StoreSalesSummary ss ON ss.total_sales = (
        SELECT 
            MAX(total_sales) 
        FROM 
            StoreSalesSummary
    )
WHERE 
    tc.total_net_paid > 100
    OR (tc.total_net_paid IS NULL AND tc.order_count = 0)
ORDER BY 
    tc.total_net_paid DESC, 
    tc.c_customer_id;
