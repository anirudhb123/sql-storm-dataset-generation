WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate < '2023-01-01'
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000
),
ExtensiveLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey, l.l_partkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT
    p.p_name,
    SUM(e.total_sales) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(s.rn, 0) AS supplier_rank,
    AVG(ps.ps_supplycost) AS avg_supply_cost
FROM part p
LEFT JOIN ExtensiveLineItems e ON p.p_partkey = e.l_partkey
LEFT JOIN orders o ON e.l_orderkey = o.o_orderkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN FilteredSuppliers s ON ps.ps_suppkey = s.s_suppkey
WHERE p.p_size > 10
GROUP BY p.p_name, s.rn
HAVING AVG(ps.ps_supplycost) < 20
ORDER BY total_sales DESC
LIMIT 10;
