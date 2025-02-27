
WITH RECURSIVE SalesData AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    
    UNION ALL
    
    SELECT cs_sold_date_sk, cs_item_sk, cs_quantity, cs_net_paid
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    
    UNION ALL
    
    SELECT ss_sold_date_sk, ss_item_sk, ss_quantity, ss_net_paid
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
ItemAggregate AS (
    SELECT 
        i_item_sk,
        SUM(ws_quantity + cs_quantity + ss_quantity) AS total_quantity,
        SUM(ws_net_paid + cs_net_paid + ss_net_paid) AS total_net_paid
    FROM SalesData
    LEFT JOIN item ON SalesData.ws_item_sk = item.i_item_sk
    GROUP BY i_item_sk
),
TopItems AS (
    SELECT i_item_sk,
           total_quantity,
           total_net_paid,
           RANK() OVER (ORDER BY total_net_paid DESC) AS rank
    FROM ItemAggregate
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    item.i_brand,
    tia.total_net_paid,
    tia.total_quantity,
    COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
    COALESCE(SUM(cr_return_quantity), 0) AS total_catalog_returns
FROM TopItems tia
JOIN item ON tia.i_item_sk = item.i_item_sk
LEFT JOIN store_returns sr ON item.i_item_sk = sr.sr_item_sk
LEFT JOIN catalog_returns cr ON item.i_item_sk = cr.cr_item_sk
WHERE tia.rank <= 10
GROUP BY item.i_item_id, item.i_item_desc, item.i_brand, tia.total_net_paid, tia.total_quantity
ORDER BY tia.total_net_paid DESC;
