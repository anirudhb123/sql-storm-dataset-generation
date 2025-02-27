
WITH RECURSIVE RevenueCTE AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
    UNION ALL
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        total_sales + COALESCE((SELECT SUM(ss_ext_sales_price) FROM store_sales WHERE ss_item_sk = ws_item_sk AND ss_sold_date_sk = ws_sold_date_sk), 0)
    FROM 
        RevenueCTE
    WHERE 
        total_sales < 100000
), RankedSales AS (
    SELECT 
        r.ws_item_sk, 
        SUM(r.total_sales) AS total_revenue,
        RANK() OVER (ORDER BY SUM(r.total_sales) DESC) AS sales_rank
    FROM 
        RevenueCTE r
    GROUP BY 
        r.ws_item_sk
), CustomerPurchase AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        c.c_customer_sk
), HighValueCustomers AS (
    SELECT 
        cp.c_customer_sk,
        cp.total_spent,
        CASE 
            WHEN cp.total_spent > 5000 THEN 'High'
            WHEN cp.total_spent BETWEEN 2000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS customer_value
    FROM 
        CustomerPurchase cp
)
SELECT 
    hvc.customer_value,
    r.total_revenue,
    COUNT(hvc.c_customer_sk) AS number_of_customers,
    AVG(hvc.total_spent) AS average_spent_per_customer
FROM 
    HighValueCustomers hvc
JOIN 
    RankedSales r ON hvc.total_spent > r.total_revenue
GROUP BY 
    hvc.customer_value, r.total_revenue
ORDER BY 
    r.total_revenue DESC, hvc.customer_value;
