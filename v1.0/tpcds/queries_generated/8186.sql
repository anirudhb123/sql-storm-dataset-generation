
WITH OrderSummary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        d.d_year,
        d.d_month_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.web_site_sk, d.d_year, d.d_month_seq
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
SalesByGender AS (
    SELECT 
        cs.cd_gender,
        SUM(cs.total_spent) AS total_sales_by_gender
    FROM 
        CustomerSummary cs
    GROUP BY 
        cs.cd_gender
),
WebSalesBySite AS (
    SELECT 
        os.web_site_sk,
        os.total_quantity,
        os.total_sales,
        sg.total_sales_by_gender
    FROM 
        OrderSummary os
    LEFT JOIN 
        SalesByGender sg ON 1=1
)
SELECT 
    w.w_warehouse_name,
    SUM(wb.total_quantity) AS overall_quantity,
    SUM(wb.total_sales) AS overall_sales,
    MAX(wb.total_sales_by_gender) AS max_sales_by_gender
FROM 
    warehouse w
JOIN 
    WebSalesBySite wb ON wb.web_site_sk = w.w_warehouse_sk
GROUP BY 
    w.w_warehouse_name
ORDER BY 
    overall_sales DESC;
