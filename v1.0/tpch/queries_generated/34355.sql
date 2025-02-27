WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
AllParts AS (
    SELECT p.p_partkey, p.p_name, p.p_type, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_type
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerRanking AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment,
           RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(os.total_revenue) DESC) AS segment_rank
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT s.s_name, r.r_name,
       COUNT(DISTINCT p.p_partkey) AS part_count,
       SUM(o.total_revenue) AS total_revenue,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       MAX(sh.level) AS max_supplier_level
FROM SupplierHierarchy sh
JOIN supplier s ON sh.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN AllParts p ON ps.ps_partkey = p.p_partkey
JOIN OrderSummary o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = s.s_nationkey)
JOIN CustomerRanking c ON o.o_custkey = c.c_custkey
WHERE o.total_revenue > (SELECT AVG(total_revenue) FROM OrderSummary)
GROUP BY s.s_name, r.r_name
HAVING COUNT(DISTINCT p.p_partkey) > 5
ORDER BY total_revenue DESC, r.r_name;
