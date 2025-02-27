WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL and s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL and s.s_acctbal < sh.s_acctbal
),
active_orders AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, l.l_returnflag, l.l_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'R'
),
supplier_avg_prices AS (
    SELECT ps.ps_suppkey, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
combined_orders AS (
    SELECT ao.o_orderkey, ao.o_totalprice, ao.o_orderstatus, s.s_name, 
           CASE 
               WHEN s.s_acctbal IS NULL THEN 'N/A' 
               ELSE 'Account Balance Available' 
           END AS balance_status
    FROM active_orders ao
    LEFT JOIN supplier_hierarchy s ON ao.o_orderstatus = 
        (SELECT MAX(o.o_orderstatus) FROM orders o WHERE o.o_orderkey = ao.o_orderkey)
)
SELECT c.c_name, 
       COUNT(DISTINCT co.o_orderkey) AS order_count, 
       SUM(co.o_totalprice) AS total_spent,
       RANK() OVER (PARTITION BY cr.s_name ORDER BY SUM(co.o_totalprice) DESC) AS rank,
       COALESCE(NULLIF(sapc.avg_supply_cost, 0), 'Cost Unavailable') AS average_supply_cost,
       CASE 
           WHEN s.s_name IS NOT NULL THEN 'Supplier exists'
           ELSE 'No supplier associated'
       END AS supplier_info
FROM customer c
LEFT JOIN combined_orders co ON c.c_custkey = co.o_custkey
LEFT JOIN supplier_avg_prices sapc ON sapc.ps_suppkey = co.o_orderkey
LEFT JOIN supplier s ON s.s_suppkey = (
      SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (
          SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = co.o_orderkey LIMIT 1)
)
GROUP BY c.c_name, s.s_name, sapc.avg_supply_cost
HAVING COUNT(DISTINCT co.o_orderkey) > 10 OR SUM(co.o_totalprice) > 1000
ORDER BY total_spent DESC, rank ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
