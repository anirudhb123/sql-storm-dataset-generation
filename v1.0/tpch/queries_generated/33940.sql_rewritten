WITH RECURSIVE customer_hierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 1 AS level
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_nationkey IS NOT NULL)

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_custkey <> ch.c_custkey AND ch.level < 5
)

SELECT 
    n.n_name AS nation_name,
    SUM(COALESCE(ps.ps_supplycost, 0)) AS total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_lineitem_price,
    MAX(s.s_acctbal) AS max_supplier_acctbal,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE n.n_name IS NOT NULL 
  AND (l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31' OR l.l_returnflag = 'R')
GROUP BY n.n_name
HAVING SUM(COALESCE(ps.ps_availqty, 0)) > 100 AND AVG(p.p_retailprice) < 50.00
ORDER BY total_supply_cost DESC
LIMIT 10;