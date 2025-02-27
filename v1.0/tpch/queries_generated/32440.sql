WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(DISTINCT n.n_nationkey) > 1
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(l.l_discount) AS avg_discount,
    COALESCE(s.name, 'Unknown') AS supplier_name,
    CASE WHEN COUNT(DISTINCT co.c_custkey) > 0 THEN 'Has Orders' ELSE 'No Orders' END AS order_status,
    rh.nation_count,
    sh.level AS supplier_level
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN CustomerOrders co ON s.s_suppkey = co.c_custkey
JOIN TopRegions rh ON s.s_nationkey = rh.r_regionkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY p.p_name, s.s_name, rh.nation_count, sh.level
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY total_revenue DESC, p.p_name;
