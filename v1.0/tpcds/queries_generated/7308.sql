
WITH SalesSummary AS (
    SELECT 
        cs.cs_item_sk, 
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_ext_tax) AS total_tax,
        d.d_year,
        d.d_quarter_seq,
        i.i_category,
        cm.cd_gender,
        ca.ca_city
    FROM 
        catalog_sales cs
    JOIN 
        date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    JOIN 
        customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cm ON c.c_current_cdemo_sk = cm.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        cs.cs_item_sk, d.d_year, d.d_quarter_seq, i.i_category, cm.cd_gender, ca.ca_city
),
WarehouseSummary AS (
    SELECT 
        ws.ws_warehouse_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_warehouse_sk
),
ReturnAnalysis AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amount) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    ss.ca_city,
    ss.i_category,
    ss.cd_gender,
    ss.total_quantity AS total_sold_quantity,
    ss.total_sales AS total_sales_amount,
    ss.total_tax AS total_sales_tax,
    ws.total_profit,
    ra.total_returns AS returns_count,
    ra.total_returned_amount
FROM 
    SalesSummary ss
LEFT JOIN 
    WarehouseSummary ws ON ss.cs_item_sk = ws.ws_warehouse_sk
LEFT JOIN 
    ReturnAnalysis ra ON ss.cs_item_sk = ra.sr_item_sk
ORDER BY 
    ss.total_sales DESC
LIMIT 100;
