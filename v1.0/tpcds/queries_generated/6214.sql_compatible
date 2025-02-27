
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity_sold, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE 
        dd.d_year = 2023 
        AND cd.cd_gender = 'M' 
        AND cd.cd_marital_status = 'S'
    GROUP BY 
        ws.web_site_sk, 
        ws.ws_item_sk
)

SELECT 
    wa.w_warehouse_id, 
    ca.ca_city,
    SUM(rs.total_quantity_sold) AS total_quantity_for_city,
    SUM(rs.total_net_profit) AS total_net_profit_for_city
FROM 
    RankedSales rs
JOIN 
    warehouse wa ON wa.w_warehouse_sk = (SELECT inv.inv_warehouse_sk FROM inventory inv WHERE inv.inv_item_sk = rs.ws_item_sk LIMIT 1)
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = rs.web_site_sk LIMIT 1)
GROUP BY 
    wa.w_warehouse_id, 
    ca.ca_city
HAVING 
    SUM(rs.total_quantity_sold) > 1000
ORDER BY 
    total_net_profit_for_city DESC;
