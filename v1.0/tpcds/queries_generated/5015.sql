
WITH sales_data AS (
  SELECT 
    d.d_year AS sales_year,
    c.c_city AS customer_city,
    p.p_promo_name AS promotion_name,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders
  FROM 
    web_sales ws
  JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE 
    d.d_year BETWEEN 2020 AND 2023
  GROUP BY 
    d.d_year, c.c_city, p.p_promo_name
),
ranked_sales AS (
  SELECT 
    sales_year,
    customer_city,
    promotion_name,
    total_net_profit,
    total_orders,
    RANK() OVER (PARTITION BY sales_year ORDER BY total_net_profit DESC) AS profit_rank
  FROM 
    sales_data
)
SELECT 
  sales_year,
  customer_city,
  promotion_name,
  total_net_profit,
  total_orders 
FROM 
  ranked_sales
WHERE 
  profit_rank <= 10
ORDER BY 
  sales_year, total_net_profit DESC;
