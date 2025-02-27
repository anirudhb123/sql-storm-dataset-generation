
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND i.i_current_price > 50.00
    GROUP BY 
        ws.web_site_id
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 10
),
SalesBreakdown AS (
    SELECT 
        r.web_site_id,
        r.total_sales,
        r.order_count,
        (SELECT SUM(total_sales) FROM RankedSales) AS grand_total,
        (r.total_sales / (SELECT SUM(total_sales) FROM RankedSales)) * 100 AS sales_percentage
    FROM 
        RankedSales r
)
SELECT 
    wb.web_site_id,
    wb.total_sales,
    wb.order_count,
    wb.grand_total,
    wb.sales_percentage
FROM 
    SalesBreakdown wb
JOIN 
    web_site ws ON wb.web_site_id = ws.web_site_id
WHERE 
    wb.sales_percentage > 20
ORDER BY 
    wb.total_sales DESC;
