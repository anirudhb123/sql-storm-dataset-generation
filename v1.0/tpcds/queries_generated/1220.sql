
WITH ranked_sales AS (
  SELECT 
    ws_item_sk,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_ext_sales_price) AS total_sales,
    RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
  FROM 
    web_sales
  GROUP BY 
    ws_item_sk
),
top_items AS (
  SELECT
    i.i_item_id,
    i.i_item_desc,
    r.total_quantity,
    r.total_sales
  FROM 
    item i
  JOIN 
    ranked_sales r ON i.i_item_sk = r.ws_item_sk
  WHERE 
    r.sales_rank <= 10
),
customer_sales AS (
  SELECT 
    c.c_customer_id,
    SUM(ws.ws_ext_sales_price) AS total_spent
  FROM 
    customer c
  JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
  GROUP BY 
    c.c_customer_id
),
high_value_customers AS (
  SELECT 
    c.c_customer_id,
    cs.total_spent
  FROM 
    customer_sales cs
  JOIN 
    customer c ON cs.c_customer_id = c.c_customer_id
  WHERE 
    cs.total_spent > (
      SELECT AVG(total_spent) FROM customer_sales
    )
)
SELECT 
  t.i_item_id,
  t.i_item_desc,
  t.total_quantity,
  t.total_sales,
  h.c_customer_id,
  h.total_spent
FROM 
  top_items t
LEFT JOIN 
  high_value_customers h ON t.total_sales > (SELECT AVG(total_sales) FROM top_items)
ORDER BY 
  t.total_sales DESC, h.total_spent DESC;
