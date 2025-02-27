WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER(PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) as rn
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
),
CustomerSpending AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    COALESCE(ps.total_availqty, 0) AS total_availqty,
    ps.avg_supplycost AS avg_supplycost,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    r.region_name,
    CTE_cust.total_spent,
    sh.s_name AS supplier_name,
    (SELECT STRING_AGG(DISTINCT sh.s_name, ', ') FROM SupplierHierarchy sh WHERE sh.s_nationkey = n.n_nationkey) AS related_suppliers
FROM part p
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN RecentOrders ro ON o.o_orderkey = ro.o_orderkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN CustomerSpending CTE_cust ON o.o_custkey = CTE_cust.c_custkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE p.p_size = ANY (ARRAY[10, 20, 30]) 
  AND l.l_shipdate IS NOT NULL
  AND sh.level <= 2
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, r.region_name, CTE_cust.total_spent, sh.s_name, ps.avg_supplycost
ORDER BY p.p_partkey;
