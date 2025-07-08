
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name AS supp_name, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
), 

OrderAmounts AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY o.o_orderkey
),

RegionStats AS (
    SELECT r.r_name,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(oa.total_amount) AS total_revenue
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN OrderAmounts oa ON p.p_partkey = oa.o_orderkey
    INNER JOIN orders o ON oa.o_orderkey = o.o_orderkey
    GROUP BY r.r_name
),

FilteredResults AS (
    SELECT r_name,
           order_count,
           total_revenue,
           RANK() OVER (PARTITION BY r_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM RegionStats
    WHERE total_revenue IS NOT NULL
)

SELECT rh.supp_name,
       rh.level,
       fr.r_name,
       fr.order_count,
       fr.total_revenue
FROM SupplierHierarchy rh
JOIN FilteredResults fr ON rh.s_acctbal = fr.order_count
WHERE rh.level <= 3 OR fr.total_revenue > 10000
ORDER BY fr.r_name, fr.revenue_rank;
