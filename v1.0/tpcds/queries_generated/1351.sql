
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sold_date_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
), 
TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws.web_site_sk) AS total_websites,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        i.i_item_desc
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    WHERE 
        inv.inv_quantity_on_hand < 10
)

SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    SUM(ts.total_sales) AS total_sales,
    RANK() OVER (ORDER BY SUM(ts.total_sales) DESC) AS sales_rank,
    inv.i_item_desc,
    COALESCE(SUM(CASE WHEN rs.rn = 1 THEN rs.ws_sales_price END), 0) AS latest_price,
    MAX(CASE WHEN cs.total_profit > 1000 THEN 'High Profit' ELSE 'Low Profit' END) AS profit_category
FROM 
    CustomerStats cs
JOIN 
    TotalSales ts ON cs.c_customer_sk = ts.ws_item_sk
LEFT JOIN 
    RankedSales rs ON ts.ws_item_sk = rs.ws_item_sk
LEFT JOIN 
    InventoryCheck inv ON inv.inv_item_sk = ts.ws_item_sk
GROUP BY 
    cs.c_customer_sk, 
    cs.c_first_name, 
    cs.c_last_name, 
    inv.i_item_desc
HAVING 
    SUM(ts.total_sales) > 500
ORDER BY 
    sales_rank;
