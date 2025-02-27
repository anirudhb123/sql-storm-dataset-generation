
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS Total_Profits,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
PromotionsApplied AS (
    SELECT 
        cs.c_customer_id,
        p.p_promo_name,
        cs.Total_Profits,
        cs.Total_Orders
    FROM 
        CustomerSales cs
    LEFT JOIN 
        promotion p ON cs.Total_Orders > 0 AND p.p_start_date_sk <= cs.Total_Orders AND (p.p_discount_active = 'Y' OR p.p_channel_email = 'Y')
),
FilteredPromotions AS (
    SELECT 
        p.c_customer_id,
        p.p_promo_name,
        p.Total_Profits,
        CASE 
            WHEN p.Total_Profits IS NULL THEN 'No Profit'
            WHEN p.Total_Profits > 1000 THEN 'High Profit'
            ELSE 'Low Profit'
        END AS Profit_Category
    FROM 
        PromotionsApplied p
    WHERE 
        p.Total_Orders >= 5 OR p.p_promo_name IS NOT NULL
)
SELECT 
    fp.c_customer_id,
    fp.p_promo_name,
    COALESCE(fp.Total_Profits, 0) AS Total_Profits,
    fp.Profit_Category,
    COALESCE((
        SELECT 
            COUNT(*) 
        FROM 
            store_sales ss
        WHERE 
            ss.ss_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id = fp.c_customer_id)
            AND ss.ss_sold_date_sk IN (SELECT DISTINCT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    ), 0) AS Store_Sales_Count
FROM 
    FilteredPromotions fp
WHERE 
    fp.Profit_Category = 'High Profit'
    OR (fp.Profit_Category = 'Low Profit' AND fp.p_promo_name IS NOT NULL)
ORDER BY 
    fp.Total_Profits DESC, fp.c_customer_id;
