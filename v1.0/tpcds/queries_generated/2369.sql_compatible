
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY')
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number, ws.ws_sold_date_sk
),
TopSales AS (
    SELECT 
        web_site_sk,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
),
SalesGrowth AS (
    SELECT 
        w.warehouse_sk,
        SUM(CASE WHEN t.t_year = 2023 THEN ts.total_sales ELSE 0 END) AS sales_2023,
        SUM(CASE WHEN t.t_year = 2022 THEN ts.total_sales ELSE 0 END) AS sales_2022,
        (SUM(CASE WHEN t.t_year = 2023 THEN ts.total_sales ELSE 0 END) - 
         SUM(CASE WHEN t.t_year = 2022 THEN ts.total_sales ELSE 0 END)) / 
         NULLIF(SUM(CASE WHEN t.t_year = 2022 THEN ts.total_sales ELSE 0 END), 0) AS growth_rate
    FROM 
        warehouse w
    LEFT JOIN 
        web_sales ws ON w.warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN 
        TopSales ts ON ws.ws_order_number = ts.web_site_sk
    JOIN 
        date_dim t ON ws.ws_sold_date_sk = t.d_date_sk
    WHERE 
        t.d_year IN (2022, 2023)
    GROUP BY 
        w.warehouse_sk
)
SELECT 
    w.warehouse_name,
    sg.sales_2022,
    sg.sales_2023,
    sg.growth_rate,
    CASE 
        WHEN sg.growth_rate > 0 THEN 'Growth'
        WHEN sg.growth_rate < 0 THEN 'Decline'
        ELSE 'Stable'
    END AS growth_status
FROM 
    SalesGrowth sg
JOIN 
    warehouse w ON sg.warehouse_sk = w.warehouse_sk
ORDER BY 
    sg.growth_rate DESC;
