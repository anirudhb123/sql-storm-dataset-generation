WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 25000
),

TopRegions AS (
    SELECT r.r_regionkey, r.r_name, SUM(o.o_totalprice) AS total_revenue
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING total_revenue > (
        SELECT AVG(o_totalprice) 
        FROM orders
    )
),

RankedSuppliers AS (
    SELECT sh.s_name, sh.level, ROW_NUMBER() OVER (PARTITION BY sh.level ORDER BY sh.s_name) AS rank
    FROM SupplierHierarchy sh
),

FinalReport AS (
    SELECT t.r_name AS region_name, 
           t.total_revenue, 
           s.s_name AS supplier_name,
           RANK() OVER (PARTITION BY t.r_regionkey ORDER BY t.total_revenue DESC) AS region_rank,
           COALESCE(DENSE_RANK() OVER (PARTITION BY sh.level ORDER BY s.s_name), 0) AS supplier_rank
    FROM TopRegions t
    LEFT JOIN RankedSuppliers s ON s.level = 0 
)

SELECT * 
FROM FinalReport 
WHERE region_rank <= 5 
  AND supplier_rank <= 10 
ORDER BY region_name, total_revenue DESC;
