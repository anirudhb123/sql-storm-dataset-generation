
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M' 
        AND i.i_current_price > 50
        AND ws.ws_sold_date_sk BETWEEN 2459356 AND 2459396
),
TopProfits AS (
    SELECT 
        w.web_site_name,
        SUM(rs.net_profit) AS total_net_profit
    FROM 
        RankedSales rs
    JOIN 
        web_site w ON rs.web_site_sk = w.web_site_sk
    WHERE 
        rs.rank <= 10
    GROUP BY 
        w.web_site_name
)
SELECT 
    tp.web_site_name,
    tp.total_net_profit
FROM 
    TopProfits tp
ORDER BY 
    tp.total_net_profit DESC;
