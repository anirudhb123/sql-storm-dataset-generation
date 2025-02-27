
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws_sold_date_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    AND cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
    GROUP BY ws.web_site_id, ws_sold_date_sk
),
TopSales AS (
    SELECT web_site_id, total_sales
    FROM RankedSales
    WHERE sales_rank <= 10
),
SalesComparison AS (
    SELECT 
        t.web_site_id,
        t.total_sales,
        ROW_NUMBER() OVER (ORDER BY t.total_sales DESC) AS sales_position
    FROM TopSales t
)
SELECT 
    sc.sales_position,
    sc.web_site_id,
    sc.total_sales,
    COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory
FROM SalesComparison sc
LEFT JOIN inventory inv ON inv.inv_warehouse_sk = (SELECT MIN(w_warehouse_sk) FROM warehouse)
GROUP BY sc.sales_position, sc.web_site_id, sc.total_sales
ORDER BY sc.sales_position;
