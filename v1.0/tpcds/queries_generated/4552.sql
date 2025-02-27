
WITH RankedSales AS (
    SELECT 
        ws.ship_date_sk,
        ws.item_sk,
        ws.net_paid,
        RANK() OVER (PARTITION BY ws.item_sk ORDER BY ws.sold_date_sk DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.item_sk = i.item_sk
    WHERE 
        ws.ship_date_sk IS NOT NULL AND 
        ws.net_paid > 0
),
CustomerTier AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.credit_rating = 'High' THEN 'Premium'
            WHEN cd.credit_rating = 'Medium' THEN 'Standard'
            ELSE 'Basic'
        END AS customer_tier
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ct.customer_tier,
        r.item_sk,
        SUM(r.net_paid) AS total_sales,
        COUNT(r.item_sk) AS sales_count
    FROM 
        RankedSales r
    JOIN 
        CustomerTier ct ON r.ship_date_sk = ct.c_customer_sk
    WHERE 
        r.rank = 1
    GROUP BY 
        ct.customer_tier, r.item_sk
)
SELECT 
    ss.customer_tier,
    i.item_desc,
    ss.total_sales,
    ss.sales_count
FROM 
    SalesSummary ss
JOIN 
    item i ON ss.item_sk = i.item_sk
LEFT JOIN 
    promotion p ON i.item_sk = p.p_item_sk
WHERE 
    ss.total_sales > 1000 AND 
    (p.promo_sk IS NULL OR p.promo_name NOT LIKE '%Discount%')
ORDER BY 
    ss.customer_tier, ss.total_sales DESC;
