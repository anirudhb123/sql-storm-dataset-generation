
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        MAX(ws_sold_date_sk) AS latest_sold_date
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY
        ws_item_sk
    HAVING
        SUM(ws_quantity) > 100
),
CustomerCTE AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rn
    FROM
        customer
    JOIN
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
HighestSpenders AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM
        CustomerCTE
    WHERE
        rn <= 10
),
InventoryStatus AS (
    SELECT
        inv_date_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_available
    FROM
        inventory
    GROUP BY
        inv_date_sk, inv_item_sk
)
SELECT
    s.store_id,
    s.store_name,
    hs.c_customer_sk,
    hs.c_first_name,
    hs.c_last_name,
    ss.total_quantity AS store_sales_quantity,
    ss.total_profit AS store_sales_profit,
    is.total_quantity_available
FROM
    store s
LEFT JOIN
    store_sales ss ON s.s_store_sk = ss.ss_store_sk
JOIN
    HighestSpenders hs ON ss.ss_customer_sk = hs.c_customer_sk
JOIN
    InventoryStatus is ON ss.ss_item_sk = is.inv_item_sk
WHERE
    is.total_quantity_available IS NOT NULL
    AND ss.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) 
                               FROM store_sales 
                               WHERE ss_item_sk = ss.ss_item_sk)
ORDER BY
    store_sales_profit DESC, store_sales_quantity DESC;
