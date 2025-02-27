
WITH RecursiveSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
), LastSale AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
        MAX(rs.ws_net_profit) AS max_net_profit
    FROM 
        RecursiveSales rs
    WHERE 
        rs.rn = 1
    GROUP BY 
        rs.ws_item_sk
), InventorySummary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
), CustomerStats AS (
    SELECT 
        c_current_cdemo_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        COALESCE(AVG(cd_purchase_estimate), 0) AS avg_purchase_estimate,
        COUNT(c_email_address) FILTER (WHERE c_email_address IS NOT NULL) AS email_customers
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c_current_cdemo_sk
)
SELECT 
    ss.ws_item_sk,
    ls.total_quantity,
    ls.total_sales,
    ls.max_net_profit,
    COALESCE(is.total_inventory, 0) AS total_inventory,
    cs.customer_count,
    cs.avg_purchase_estimate,
    cs.email_customers
FROM 
    LastSale ls
LEFT JOIN 
    InventorySummary is ON ls.ws_item_sk = is.inv_item_sk
LEFT JOIN 
    CustomerStats cs ON ls.ws_item_sk IN (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_sold_date_sk = (
                SELECT 
                    MAX(ws_sold_date_sk) FROM web_sales
            )
    )
WHERE 
    ls.total_sales > (
        SELECT 
            AVG(total_sales) 
        FROM (
            SELECT 
                SUM(ws_sales_price * ws_quantity) AS total_sales
            FROM 
                web_sales
            WHERE 
                ws_sold_date_sk BETWEEN (
                    SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022
                ) AND (
                    SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022
                )
            GROUP BY 
                ws_item_sk
        ) AS DailySales
    )
ORDER BY 
    ls.total_sales DESC
LIMIT 100;
