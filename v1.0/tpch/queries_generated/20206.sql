WITH RECURSIVE cte_supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           CASE WHEN s.s_acctbal IS NULL THEN 'Unknown' ELSE 'Known' END AS balance_status
    FROM supplier s
    WHERE s.s_acctbal > 0
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 'Recycled'
    FROM supplier s
    JOIN cte_supplier cs ON s.s_suppkey = cs.s_suppkey
    WHERE s.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier)
),
cte_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
),
order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN cte_orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL OR COUNT(o.o_orderkey) > 5
)
SELECT p.p_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       rt.r_name AS region_name,
       nt.n_name AS nation_name,
       CASE 
           WHEN SUM(l.l_quantity) >= 100 THEN 'High Volume'
           WHEN SUM(l.l_quantity) BETWEEN 50 AND 99 THEN 'Medium Volume'
           ELSE 'Low Volume'
       END AS volume_category,
       (SELECT COUNT(*) FROM cte_supplier 
        WHERE balance_status = 'Unknown' AND s_suppkey IN (
            SELECT DISTINCT ps.ps_suppkey 
            FROM partsupp ps 
            WHERE ps.ps_partkey = p.p_partkey)
       ) AS unknown_supplier_count
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation nt ON s.s_nationkey = nt.n_nationkey
JOIN region rt ON nt.n_regionkey = rt.r_regionkey
LEFT JOIN order_summary os ON os.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
GROUP BY p.p_name, rt.r_name, nt.n_name
ORDER BY total_revenue DESC
LIMIT 10
OFFSET 5
UNION ALL
SELECT 'Total' AS p_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)), 
       NULL, NULL, NULL, 
       (SELECT COUNT(*) FROM cte_supplier WHERE balance_status = 'Recycled') 
FROM lineitem l
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31';
