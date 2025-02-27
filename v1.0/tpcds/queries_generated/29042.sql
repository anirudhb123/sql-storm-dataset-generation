
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        item i
    WHERE 
        i.i_current_price > 50.00
),
RecentSales AS (
    SELECT 
        ws.ws_order_number,
        cs.cs_order_number AS catalog_order_number,
        ss.ss_order_number AS store_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        ws.ws_item_sk,
        cd.c_customer_id
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    LEFT JOIN 
        store_sales ss ON ws.ws_order_number = ss.ss_ticket_number
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_id
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
),
ItemSaleSummary AS (
    SELECT 
        item.i_item_id,
        COUNT(*) AS sale_count,
        SUM(item.ws_sales_price) AS total_sales,
        AVG(item.ws_sales_price) AS avg_price
    FROM 
        RecentSales item
    GROUP BY 
        item.i_item_id
)
SELECT 
    cs.full_name,
    isd.i_item_id,
    isd.sale_count,
    isd.total_sales,
    isd.avg_price
FROM 
    ItemSaleSummary isd
JOIN 
    CustomerDetails cs ON cs.c_customer_id = (SELECT DISTINCT ws_bill_customer_sk FROM RecentSales)
WHERE 
    isd.total_sales > 500
ORDER BY 
    isd.total_sales DESC;
