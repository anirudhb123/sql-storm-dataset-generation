WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey = 1
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM RankedSuppliers s
    WHERE s.rank <= 3
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
       c.c_name AS customer_name, s.s_name AS supplier_name,
       RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank,
       CASE 
           WHEN r.r_name IS NULL THEN 'Unknown Region'
           ELSE r.r_name
       END AS region_name
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN partsupp ps ON ps.ps_partkey = p.p_partkey
JOIN TopSuppliers s ON ps.ps_suppkey = s.s_suppkey
JOIN customer c ON c.c_custkey = l.l_orderkey
LEFT JOIN nation n ON n.n_nationkey = c.c_nationkey
LEFT JOIN region r ON r.r_regionkey = n.n_regionkey
WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
AND c.c_acctbal IS NOT NULL
GROUP BY p.p_partkey, p.p_name, c.c_name, s.s_name, r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_sales DESC, region_name;
