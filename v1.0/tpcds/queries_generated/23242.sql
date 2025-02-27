
WITH RankedCustomers AS (
  SELECT 
    c.c_customer_sk,
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
  FROM 
    customer c
  JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
StoreSalesCTE AS (
  SELECT 
    ss.ss_item_sk,
    SUM(ss.ss_quantity) AS total_quantity,
    AVG(ss.ss_sales_price) AS avg_sales_price
  FROM 
    store_sales ss
  WHERE 
    ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
  GROUP BY 
    ss.ss_item_sk
),
WebSalesCTE AS (
  SELECT 
    ws.ws_item_sk,
    SUM(ws.ws_quantity) AS total_quantity_web,
    SUM(ws.ws_net_paid) AS total_net_paid_web
  FROM 
    web_sales ws
  JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE 
    d.d_current_year = 2023
  GROUP BY 
    ws.ws_item_sk
),
CombinedSales AS (
  SELECT 
    coalesce(ss.ss_item_sk, ws.ws_item_sk) AS item_sk,
    COALESCE(ss.total_quantity, 0) AS store_quantity,
    COALESCE(ws.total_quantity_web, 0) AS web_quantity,
    (COALESCE(ss.total_quantity, 0) + COALESCE(ws.total_quantity_web, 0)) AS total_quantity,
    (COALESCE(ss.avg_sales_price * ss.total_quantity, 0) + COALESCE(ws.total_net_paid_web, 0)) AS total_sales
  FROM 
    StoreSalesCTE ss
  FULL OUTER JOIN 
    WebSalesCTE ws ON ss.ss_item_sk = ws.ws_item_sk
)
SELECT 
  rc.c_customer_id AS top_customer_id,
  cs.item_sk,
  cs.total_quantity,
  cs.total_sales,
  (case when cs.total_sales > 10000 then 'High Spender' else 'Regular' end) AS customer_category
FROM 
  RankedCustomers rc
JOIN 
  CombinedSales cs ON rc.c_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_first_name = 'John' LIMIT 1)
WHERE 
  rc.rnk = 1
  AND cs.total_quantity > (SELECT AVG(total_quantity) FROM CombinedSales)
ORDER BY 
  cs.total_sales DESC
LIMIT 10;
