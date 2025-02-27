
WITH RECURSIVE cte_part_supp AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    UNION ALL
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) 
    FROM partsupp ps
    JOIN cte_part_supp cte ON ps.ps_partkey = cte.ps_partkey
    GROUP BY ps.ps_partkey
),
cte_customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, 
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY COUNT(o.o_orderkey) DESC) AS rank_order
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_nationkey
)
SELECT 
    p.p_partkey, 
    p.p_name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue,
    AVG(p.p_retailprice) AS avg_retail_price,
    ns.n_name AS supplier_nation,
    CASE 
        WHEN SUM(li.l_quantity) > 100 THEN 'High Volume'
        ELSE 'Low Volume' 
    END AS volume_category,
    COALESCE(ROUND(AVG(co.order_count), 2), 0) AS avg_orders_per_customer
FROM part p
JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN cte_customer_orders co ON co.c_custkey = li.l_suppkey
GROUP BY p.p_partkey, p.p_name, ns.n_name
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 1000 
   AND AVG(p.p_retailprice) < 50
ORDER BY revenue DESC;
