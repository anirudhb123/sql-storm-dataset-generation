
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (
            SELECT 
                MAX(d.d_date_sk)
            FROM 
                date_dim d
            WHERE 
                d.d_year = 2023
        )
), 
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS TotalQuantity,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS TotalSales
    FROM 
        RankedSales rs
    WHERE 
        rs.SalesRank <= 10
    GROUP BY 
        rs.ws_item_sk
), 
CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS TotalSpent
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE 
        ss.ss_sold_date_sk = (
            SELECT 
                MAX(d.d_date_sk)
            FROM 
                date_dim d
            WHERE 
                d.d_year = 2023
        )
    GROUP BY 
        c.c_customer_id
), 
SalesSummary AS (
    SELECT 
        t.ws_item_sk,
        COALESCE(cs.TotalSpent, 0) AS CustomerTotalSpent,
        ti.TotalQuantity,
        ti.TotalSales
    FROM 
        TopItems ti
    LEFT JOIN 
        CustomerSales cs ON ti.ws_item_sk = cs.c_customer_id
)
SELECT 
    s.ws_item_sk,
    s.TotalQuantity,
    s.TotalSales,
    CASE 
        WHEN s.CustomerTotalSpent > 0 THEN 
            (s.TotalSales / s.CustomerTotalSpent) * 100
        ELSE 
            NULL
    END AS SalesToCustomerRatio
FROM 
    SalesSummary s
ORDER BY 
    s.TotalSales DESC
LIMIT 15;
