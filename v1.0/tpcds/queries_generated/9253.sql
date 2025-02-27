
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id, cd.cd_gender
),
top_selling_items AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        RANK() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY 
        i.i_item_id
)
SELECT 
    rs.web_site_id,
    rs.cd_gender,
    rs.total_profit,
    tsi.i_item_id,
    tsi.total_quantity_sold
FROM 
    ranked_sales rs
JOIN 
    top_selling_items tsi ON rs.web_site_id = (SELECT 
                                                   web_site_id 
                                               FROM 
                                                   web_site 
                                               WHERE 
                                                   web_site_sk = rs.web_site_id) 
WHERE 
    rs.profit_rank = 1 
    AND tsi.sales_rank <= 10
ORDER BY 
    rs.web_site_id, rs.cd_gender, tsi.total_quantity_sold DESC;
