
WITH SalesData AS (
    SELECT 
        w.w_warehouse_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE 
        ws.ws_sold_date_sk = (
            SELECT MAX(d.d_date_sk)
            FROM date_dim d
            WHERE d.d_year = 2023
        )
    GROUP BY 
        w.w_warehouse_name
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(rs.sr_ticket_number) AS return_count,
        SUM(rs.sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns rs ON c.c_customer_sk = rs.sr_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
ReturnAnalysis AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.cd_marital_status,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count,
        SUM(cr.cr_return_amt) AS total_catalog_return_amt
    FROM 
        CustomerStatistics cs
    LEFT JOIN 
        catalog_returns cr ON cs.c_customer_id = cr.cr_returning_customer_sk
    GROUP BY 
        cs.c_customer_id, cs.cd_gender, cs.cd_marital_status
)
SELECT 
    sd.w_warehouse_name,
    sd.total_sales,
    sd.order_count,
    ca.c_customer_id,
    ca.cd_gender,
    ca.cd_marital_status,
    COALESCE(ca.return_count, 0) AS return_count,
    COALESCE(ca.total_return_amt, 0) AS total_return_amt,
    COALESCE(ra.catalog_return_count, 0) AS catalog_return_count,
    COALESCE(ra.total_catalog_return_amt, 0) AS total_catalog_return_amt
FROM 
    SalesData sd
FULL OUTER JOIN 
    CustomerStatistics ca ON sd.w_warehouse_name = ca.c_customer_id
FULL OUTER JOIN 
    ReturnAnalysis ra ON ca.c_customer_id = ra.c_customer_id
WHERE 
    sd.total_sales IS NOT NULL OR ca.return_count IS NOT NULL OR ra.catalog_return_count IS NOT NULL
ORDER BY 
    sd.total_sales DESC NULLS LAST, ca.c_customer_id;
