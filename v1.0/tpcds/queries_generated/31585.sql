
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS site_rank
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws.web_site_sk, ws.web_name, w.w_warehouse_id
),
AddressWithDemographics AS (
    SELECT 
        ca.ca_city,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(COALESCE(cd.cd_dep_count, 0)) AS total_dependents
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_city, cd.cd_gender
),
SalesReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_value
    FROM store_returns
    GROUP BY sr_item_sk
),
JoinedSalesData AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_sold,
        COALESCE(SUM(sr.total_returns), 0) AS total_returns,
        COALESCE(SUM(sr.total_returned_value), 0) AS returned_value,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN SalesReturns sr ON ws.ws_item_sk = sr.sr_item_sk
    WHERE i.i_rec_start_date <= CURRENT_DATE 
    AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
    GROUP BY i.i_item_id, i.i_item_desc
)
SELECT 
    sh.web_name,
    sh.w_warehouse_id,
    sd.i_item_id,
    sd.i_item_desc,
    sd.total_sold,
    sd.total_returns,
    sd.returned_value,
    sd.avg_net_profit,
    ad.ca_city,
    ad.cd_gender,
    ad.customer_count,
    ad.total_dependents
FROM SalesHierarchy sh
JOIN JoinedSalesData sd ON sh.web_site_sk = sd.ws_bill_customer_sk
JOIN AddressWithDemographics ad ON sh.web_name = ad.ca_city
WHERE sh.total_profit > 10000
  AND (ad.cd_gender = 'F' OR ad.total_dependents > 2)
ORDER BY sh.total_profit DESC, sd.avg_net_profit DESC;
