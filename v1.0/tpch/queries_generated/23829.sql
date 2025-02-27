WITH recursive x AS (
    SELECT c_nationkey, COUNT(*) AS cust_count
    FROM customer
    GROUP BY c_nationkey
), 
y AS (
    SELECT n_nationkey, n_name, 
           COALESCE((SELECT SUM(o_totalprice) 
                     FROM orders o 
                     WHERE o.o_custkey IN (SELECT c_custkey FROM customer WHERE c_nationkey = n.n_nationkey)), 0) AS total_sales
    FROM nation n
), 
z AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_availqty, 
           LEAD(p.p_retailprice) OVER (ORDER BY p.p_partkey) AS next_price,
           LAG(ps.ps_availqty) OVER (ORDER BY ps.ps_partkey) AS previous_avail
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
), 
sales_data AS (
    SELECT n.n_name, y.total_sales, x.cust_count, z.p_name, 
           (CASE WHEN z.next_price IS NULL THEN 'N/A' ELSE z.next_price END) AS next_part_price,
           (CASE 
               WHEN x.cust_count > 100 THEN 'High' 
               WHEN x.cust_count > 50 THEN 'Medium' 
               ELSE 'Low' 
           END) AS customer_category
    FROM y
    INNER JOIN x ON y.n_nationkey = x.cust_count
    LEFT JOIN z ON z.p_partkey IS NOT NULL
)

SELECT sd.n_name, 
       SUM(sd.total_sales) AS sum_sales,
       COUNT(DISTINCT sd.p_name) AS unique_parts_sold,
       AVG(sd.next_part_price::decimal) AS avg_next_price,
       COUNT(*) FILTER (WHERE sd.customer_category = 'High') AS high_category_count
FROM sales_data sd
GROUP BY sd.n_name
HAVING SUM(sd.total_sales) > (SELECT AVG(total_sales) FROM sales_data)
ORDER BY sum_sales DESC
LIMIT 10;
