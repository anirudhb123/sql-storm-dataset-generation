WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, sh.level + 1
    FROM SupplierHierarchy sh
    JOIN supplier s2 ON sh.s_nationkey = s2.s_nationkey AND sh.s_suppkey <> s2.s_suppkey
    WHERE sh.level < 2
),
TopRegions AS (
    SELECT r.r_regionkey, r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM region r
    JOIN nation n ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
RankedSuppliers AS (
    SELECT sh.s_name, sh.level, RANK() OVER (PARTITION BY sh.level ORDER BY s.s_acctbal DESC) AS rank
    FROM SupplierHierarchy sh
    JOIN supplier s ON s.s_suppkey = sh.s_suppkey
),
FinalResults AS (
    SELECT tr.r_name AS region_name, co.c_name AS customer_name, 
           rs.s_name AS supplier_name, co.total_spent,
           tr.total_revenue, 
           COALESCE(co.total_spent / NULLIF(tr.total_revenue, 0), 0) AS spent_percentage 
    FROM TopRegions tr
    JOIN CustomerOrders co ON co.total_spent > 10000
    JOIN RankedSuppliers rs ON rs.rank = 1
)
SELECT f.region_name, f.customer_name, f.supplier_name, f.total_spent, 
       f.total_revenue, f.spent_percentage
FROM FinalResults f
ORDER BY f.region_name, f.total_spent DESC
LIMIT 10;
