
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER(PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_quantity,
        ri.total_net_paid,
        i.i_item_desc,
        p.p_promo_name
    FROM 
        RankedSales ri
    LEFT JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        promotion p ON i.i_item_sk = p.p_item_sk
    WHERE 
        ri.rank <= 10
),
ItemDetails AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_net_paid,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        ws.web_company_name
    FROM 
        TopItems ti
    JOIN 
        customer c ON c.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ti.ws_item_sk LIMIT 1)
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_site ws ON ws.web_site_sk = (SELECT ws_web_site_sk FROM web_sales WHERE ws_item_sk = ti.ws_item_sk LIMIT 1)
)
SELECT 
    id.ws_item_sk,
    id.total_quantity,
    id.total_net_paid,
    id.ca_city,
    id.ca_state,
    id.cd_gender,
    id.cd_marital_status,
    id.web_company_name
FROM 
    ItemDetails id
ORDER BY 
    id.total_net_paid DESC;
