WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal * 1.1, level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 3
),
PartAggregation AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty * (CASE WHEN ps.ps_supplycost IS NULL THEN 0 ELSE ps.ps_supplycost END)) AS total_supplycost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT DISTINCT
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COALESCE(p.total_supplycost, 0) AS part_cost,
    CASE
        WHEN n.supplier_count IS NULL THEN 'No Suppliers'
        ELSE n.supplier_count::varchar
    END AS supplier_status,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY revenue DESC) AS rank_in_nation,
    CONCAT(n.n_name, ' in ', n.region_name) AS detailed_nation
FROM orders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN PartAggregation p ON p.p_partkey = l.l_partkey
JOIN NationDetails n ON c.c_nationkey = n.n_nationkey
WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
AND l.l_quantity IS NOT NULL
GROUP BY c.c_name, part_cost, detailed_nation, n.supplier_count
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY revenue DESC, detailed_nation ASC
OFFSET 10 ROWS
FETCH NEXT 5 ROWS ONLY;
