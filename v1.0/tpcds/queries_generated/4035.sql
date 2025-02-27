
WITH AggregateSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
TopWebSites AS (
    SELECT
        ag.web_site_id,
        ag.total_quantity_sold,
        ag.total_net_profit,
        ag.total_orders,
        ag.avg_sales_price
    FROM 
        AggregateSales ag
    WHERE 
        ag.rank <= 5
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_age_group,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
CustomerRanking AS (
    SELECT 
        ct.c_customer_id,
        ct.ca_city,
        ct.ca_state,
        ct.cd_gender,
        COALESCE(rd.reason_desc, 'No reason') AS return_reason,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM 
        CustomerDetails ct
    LEFT JOIN 
        store_returns sr ON ct.c_customer_id = sr.sr_customer_sk
    LEFT JOIN 
        reason rd ON sr.sr_reason_sk = rd.r_reason_sk
    WHERE 
        ct.customer_rank <= 10
    GROUP BY 
        ct.c_customer_id, ct.ca_city, ct.ca_state, ct.cd_gender, rd.reason_desc
)
SELECT 
    cw.web_site_id,
    cw.total_quantity_sold,
    cw.total_net_profit,
    cu.c_customer_id,
    cu.ca_city,
    cu.ca_state,
    cu.cd_gender,
    cu.return_reason,
    cu.return_count
FROM 
    TopWebSites cw
JOIN 
    CustomerRanking cu ON (cw.total_net_profit > 5000 OR cw.total_quantity_sold > 100) AND (cu.return_count IS NOT NULL)
ORDER BY 
    cw.total_net_profit DESC, cu.return_count ASC;
