
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        cd.cd_marital_status = 'M' OR cd.cd_gender = 'F'
    GROUP BY 
        ws.web_site_id
),
FilteredReturns AS (
    SELECT 
        sr.returning_customer_sk,
        SUM(sr.return_quantity) AS total_returns,
        COUNT(sr.return_ticket_number) AS return_count
    FROM 
        store_returns sr
    LEFT JOIN 
        customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL AND sr.returned_date_sk > (
            SELECT 
                MAX(d.d_date_sk) 
            FROM 
                date_dim d WHERE d.d_year = 2023
        )
    GROUP BY 
        sr.returning_customer_sk
)
SELECT 
    r.web_site_id,
    r.total_sales,
    r.order_count,
    COALESCE(f.total_returns, 0) AS return_count,
    CASE 
        WHEN r.total_sales > 10000 THEN 'High Performer'
        WHEN r.total_sales BETWEEN 5000 AND 10000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category,
    DENSE_RANK() OVER (ORDER BY r.total_sales DESC) AS overall_rank
FROM 
    RankedSales r
LEFT JOIN 
    FilteredReturns f ON r.web_site_id = (
        SELECT 
            ws.web_site_id 
        FROM 
            web_sales ws 
        JOIN 
            customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
        WHERE 
            c.c_customer_sk = f.returning_customer_sk
        FETCH FIRST 1 ROW ONLY
    )
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;
