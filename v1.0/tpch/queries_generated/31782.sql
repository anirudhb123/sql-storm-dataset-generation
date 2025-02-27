WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS acct_rank
    FROM supplier s
    WHERE s.s_acctbal > 10000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT p.p_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       COALESCE(ns.n_name, 'Unknown') AS nation_name,
       RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey
LEFT JOIN NationHierarchy nh ON rs.s_nationkey = nh.n_nationkey
LEFT JOIN nation ns ON nh.n_nationkey = ns.n_nationkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
  AND (p.p_size BETWEEN 10 AND 20 OR p.p_brand = 'Brand#23')
GROUP BY p.p_name, ns.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY revenue_rank;
