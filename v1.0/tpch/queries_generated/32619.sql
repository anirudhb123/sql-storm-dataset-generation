WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey
)

SELECT 
    r.r_name,
    n.n_name,
    p.p_name,
    SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * l.l_quantity) DESC) AS nation_rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
JOIN orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    l.l_shipdate > '2022-01-01' 
    AND l.l_returnflag = 'N' 
    AND (o.o_orderstatus = 'F' OR o.o_orderstatus = 'O')
GROUP BY r.r_name, n.n_name, p.p_name
HAVING SUM(ps.ps_supplycost * l.l_quantity) > 5000
ORDER BY r.r_name, total_supply_cost DESC
OFFSET (SELECT COUNT(*) FROM supplier_hierarchy) ROWS FETCH NEXT 10 ROWS ONLY;
