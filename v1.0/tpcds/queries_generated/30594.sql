
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY ws_item_sk
    HAVING SUM(ws_ext_sales_price) > 1000
),
TopItems AS (
    SELECT
        item.i_item_sk,
        item.i_item_id,
        item.i_product_name,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_quantity,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(ws.ws_quantity), 0) + COALESCE(SUM(cs.cs_quantity), 0) DESC) AS overall_rank
    FROM item
    LEFT JOIN web_sales ws ON item.i_item_sk = ws.ws_item_sk AND ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    LEFT JOIN catalog_sales cs ON item.i_item_sk = cs.cs_item_sk AND cs.cs_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY item.i_item_sk, item.i_item_id, item.i_product_name
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_quantity ELSE 0 END) AS sold_quantity,
    AVG(COALESCE(cs.cs_sales_price, 0)) AS avg_catalog_price,
    (SELECT COUNT(DISTINCT cd_demo_sk)
     FROM customer_demographics cd
     WHERE cd.cd_income_band_sk IN (
           SELECT ib_income_band_sk 
           FROM income_band 
           WHERE ib_lower_bound < 50000 AND ib_upper_bound > 30000
      )
    ) AS potential_customers,
    (SELECT COUNT(*)
     FROM SalesCTE
     WHERE rank <= 10
    ) AS top_selling_items
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN TopItems ti ON ti.i_item_sk = ss.ss_item_sk
GROUP BY ca.ca_city, ca.ca_state
ORDER BY SUM(ws.ws_quantity) DESC, ca.ca_city;
