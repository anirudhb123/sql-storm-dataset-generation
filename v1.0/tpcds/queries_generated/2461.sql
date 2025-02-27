
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND dd.d_moy IN (6, 7)
    GROUP BY 
        ws.web_site_id
),
ReturnData AS (
    SELECT 
        wr.wr_web_site_sk,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns
    FROM 
        web_returns wr
    JOIN 
        web_site ws ON wr.wr_web_page_sk = ws.web_site_sk
    WHERE 
        wr.wr_returned_date_sk IN (SELECT DISTINCT dd.d_date_sk FROM date_dim dd WHERE dd.d_year = 2023 AND dd.d_moy IN (6, 7))
    GROUP BY 
        wr.wr_web_site_sk
),
CustomerData AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)

SELECT 
    sd.web_site_id,
    sd.total_profit,
    sd.total_orders,
    rd.total_return_amount,
    rd.total_returns,
    cd.customer_count,
    cd.avg_purchase_estimate,
    COALESCE(sd.total_profit, 0) - COALESCE(rd.total_return_amount, 0) AS net_profit,
    CASE 
        WHEN cd.customer_count > 100 THEN 'High Customer Engagement'
        ELSE 'Low Customer Engagement'
    END AS engagement_level
FROM 
    SalesData sd
FULL OUTER JOIN 
    ReturnData rd ON sd.web_site_id = rd.wr_web_site_sk
FULL OUTER JOIN 
    CustomerData cd ON 1=1
WHERE 
    sd.rank_profit <= 10
ORDER BY 
    net_profit DESC;
