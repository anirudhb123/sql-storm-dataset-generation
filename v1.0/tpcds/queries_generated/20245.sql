
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws.net_paid,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank,
        COALESCE(NULLIF(ws_ext_discount_amt, 0), NULL) AS effective_discount,
        SUM(ws_quantity) OVER (PARTITION BY ws.web_site_sk) AS total_quantity,
        DENSE_RANK() OVER (ORDER BY ws.net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) 
                             FROM date_dim 
                             WHERE d_year = 2023)
        AND c.c_birth_year BETWEEN 1980 AND 2000
        AND (COALESCE(cd.cd_marital_status, '') != 'S' OR cd.cd_gender = 'F')
)

SELECT 
    w.warehouse_name,
    SUM(s.net_paid) AS total_sales,
    COUNT(DISTINCT s.web_site_sk) AS unique_sites,
    AVG(s.effective_discount) AS avg_discount,
    SUM(s.total_quantity) AS total_items_sold
FROM 
    sales_summary s
OUTER JOIN 
    warehouse w ON w.warehouse_sk = (SELECT inv.inv_warehouse_sk 
                                      FROM inventory inv 
                                      WHERE inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory))
WHERE 
    s.sales_rank <= 10
GROUP BY 
    w.warehouse_name
HAVING 
    SUM(s.net_profit) IS NOT NULL AND AVG(s.avg_discount) < 5.00
ORDER BY 
    total_sales DESC
LIMIT 5
