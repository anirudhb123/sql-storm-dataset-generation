
WITH SalesSummary AS (
    SELECT 
        sd.d_year AS SaleYear,
        c.c_gender AS CustomerGender,
        SUM(ws.ws_ext_sales_price) AS TotalSales,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        COUNT(DISTINCT c.c_customer_sk) AS UniqueCustomers
    FROM 
        web_sales AS ws
    JOIN 
        customer AS c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim AS sd ON ws.ws_sold_date_sk = sd.d_date_sk
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        store AS s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        sd.d_year BETWEEN 2019 AND 2023
        AND c.c_current_cdemo_sk IS NOT NULL
        AND i.i_current_price > 0
    GROUP BY 
        sd.d_year, c.c_gender
),

PromotionsUsage AS (
    SELECT 
        p.p_promo_name AS PromoName,
        SUM(cs.cs_ext_sales_price) AS TotalPromoSales,
        COUNT(DISTINCT cs.cs_order_number) AS PromoOrderCount,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS UniquePromoCustomers
    FROM 
        catalog_sales AS cs
    JOIN 
        promotion AS p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE 
        p.p_start_date_sk IS NOT NULL 
        AND p.p_end_date_sk IS NOT NULL
        AND cs.cs_sold_date_sk BETWEEN 20190101 AND 20231231
    GROUP BY 
        p.promo_name
),

CombinedSummary AS (
    SELECT 
        ss.SaleYear,
        ss.CustomerGender,
        ss.TotalSales,
        ss.TotalOrders,
        ss.UniqueCustomers,
        pu.PromoName,
        pu.TotalPromoSales,
        pu.PromoOrderCount,
        pu.UniquePromoCustomers
    FROM 
        SalesSummary AS ss
    LEFT JOIN 
        PromotionsUsage AS pu ON ss.SaleYear = EXTRACT(YEAR FROM CURRENT_DATE) -- Example condition for joining summaries
)

SELECT 
    SaleYear,
    CustomerGender,
    TotalSales,
    TotalOrders,
    UniqueCustomers,
    PromoName,
    COALESCE(TotalPromoSales, 0) AS TotalPromoSales,
    COALESCE(PromoOrderCount, 0) AS PromoOrderCount,
    COALESCE(UniquePromoCustomers, 0) AS UniquePromoCustomers
FROM 
    CombinedSummary
ORDER BY 
    SaleYear, CustomerGender;
