
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) as rank_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_month_seq BETWEEN 1 AND 12
        AND ws.ws_net_profit > 0
    GROUP BY 
        ws.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_country
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
FilteredReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_returned_date_sk) AS total_returned_items,
        SUM(sr_return_amt) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
    HAVING 
        SUM(sr_returned_date_sk) > 0
),
FinalResults AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cr.cr_item_sk) AS total_items_returned,
        SUM(cr.cr_return_amount) AS total_amount_returned,
        rs.total_profit,
        rs.order_count
    FROM 
        CustomerDemographics cd
    LEFT JOIN 
        FilteredReturns fr ON cd.cd_demo_sk = fr.sr_returning_customer_sk
    LEFT JOIN 
        RankedSales rs ON cd.cd_demo_sk = fr.sr_returning_customer_sk
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status, 
        rs.total_profit, 
        rs.order_count
)
SELECT 
    fr.cd_gender,
    fr.cd_marital_status,
    COALESCE(fr.total_items_returned, 0) AS items_returned,
    COALESCE(fr.total_amount_returned, 0) AS amount_returned,
    fr.total_profit,
    fr.order_count,
    CASE 
        WHEN fr.total_profit IS NULL THEN 'No Profit'
        WHEN fr.order_count < 5 THEN 'Low Orders'
        ELSE 'Normal Activity'
    END AS activity_status
FROM 
    FinalResults fr
ORDER BY 
    fr.total_profit DESC, fr.order_count ASC
LIMIT 100;
