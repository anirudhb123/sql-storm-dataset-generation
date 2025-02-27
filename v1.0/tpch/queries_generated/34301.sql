WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartSupplierStats AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        AVG(ps.ps_supplycost) AS avg_supplycost, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    sh.s_name AS supplier_name,
    p.ps_partkey,
    p.avg_supplycost,
    p.supplier_count,
    o.o_orderkey,
    h.total_value
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN PartSupplierStats p ON p.p_partkey = (SELECT ps.ps_partkey 
                                                   FROM partsupp ps 
                                                   WHERE ps.ps_suppkey = sh.s_suppkey 
                                                   ORDER BY ps.ps_supplycost LIMIT 1)
LEFT JOIN HighValueOrders h ON h.o_orderkey = (SELECT o.o_orderkey 
                                                FROM orders o 
                                                WHERE o.o_custkey = (SELECT c.c_custkey 
                                                                     FROM customer c 
                                                                     WHERE c.c_nationkey = n.n_nationkey 
                                                                     LIMIT 1) 
                                                ORDER BY o.o_totalprice DESC LIMIT 1)
WHERE sh.level <= 3
ORDER BY r.r_name, n.n_name, sh.s_name;
