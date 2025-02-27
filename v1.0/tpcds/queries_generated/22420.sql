
WITH RankedSales AS (
    SELECT 
        ss.sold_date_sk,
        ss.store_sk,
        ss.item_sk,
        ss.quantity,
        ss.net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss.store_sk ORDER BY ss.net_paid DESC) AS rank_per_store
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
TotalSales AS (
    SELECT 
        r.store_sk,
        SUM(r.net_paid) AS total_net_paid,
        COUNT(r.item_sk) AS total_items_sold
    FROM 
        RankedSales r
    WHERE 
        r.rank_per_store <= 10
    GROUP BY 
        r.store_sk
),
StoreDetails AS (
    SELECT 
        s.store_sk,
        s.store_name,
        s.city,
        s.state,
        s.country,
        COALESCE(t.total_net_paid, 0) AS total_sales,
        COALESCE(t.total_items_sold, 0) AS total_items
    FROM 
        store s
    LEFT JOIN 
        TotalSales t ON s.store_sk = t.store_sk
),
CustomerMetrics AS (
    SELECT 
        cd.gender,
        cd.marital_status,
        SUM(case when ws.net_profit IS NULL THEN 0 ELSE ws.net_profit END) AS total_profit,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cd.gender, cd.marital_status
)
SELECT 
    sd.store_name,
    sd.city,
    sd.state,
    sd.country,
    cm.gender,
    cm.marital_status,
    sd.total_sales,
    sd.total_items,
    cm.total_profit,
    cm.num_customers
FROM 
    StoreDetails sd
CROSS JOIN 
    CustomerMetrics cm
WHERE 
    sd.total_sales >= 10000 AND
    cm.num_customers > (SELECT AVG(num_customers) FROM CustomerMetrics)
ORDER BY 
    sd.total_sales DESC, cm.total_profit DESC;
