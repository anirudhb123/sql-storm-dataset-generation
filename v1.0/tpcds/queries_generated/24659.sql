
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.quantity AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.net_paid) DESC) AS rank_sales
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status IS NOT NULL
    GROUP BY 
        ws.web_site_id, ws.quantity
), 
SalesReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns wr
    WHERE 
        wr.wr_return_amt_inc_tax IS NOT NULL
    GROUP BY 
        wr.wr_item_sk
), 
SalesInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    WHERE 
        inv.inv_quantity_on_hand < (SELECT AVG(inv_quantity_on_hand) FROM inventory)
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    rs.web_site_id,
    COALESCE(SUM(rs.total_sales), 0) AS total_sales,
    COALESCE(SUM(sr.total_returns), 0) AS total_returns,
    COALESCE(SI.total_inventory, 0) AS total_inventory,
    CASE 
        WHEN COALESCE(SUM(rs.total_sales), 0) = 0 THEN 'No Sales'
        WHEN COALESCE(SUM(sr.total_returns), 0) > COALESCE(SUM(rs.total_sales), 0) THEN 'High Returns'
        ELSE 'Normal'
    END AS sales_status
FROM 
    RankedSales rs
LEFT JOIN 
    SalesReturns sr ON rs.web_site_id = sr.wr_item_sk
LEFT JOIN 
    SalesInventory SI ON rs.web_site_id = SI.inv_item_sk
WHERE 
    rs.rank_sales = 1
GROUP BY 
    rs.web_site_id, SI.total_inventory
ORDER BY 
    total_sales DESC, total_returns ASC;
