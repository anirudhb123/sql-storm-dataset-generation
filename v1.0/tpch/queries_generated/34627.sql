WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
HighValueParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
    HAVING total_cost > 10000
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, RANK() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
)
SELECT DISTINCT 
    p.p_name AS part_name,
    r.r_name AS region_name,
    COALESCE(c.c_name, 'Unknown') AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    sh.level AS supplier_level,
    CASE 
        WHEN o.o_orderstatus = 'O' THEN 'Open'
        ELSE 'Closed'
    END AS order_status
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN part p ON l.l_partkey = p.p_partkey
JOIN RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey
LEFT JOIN SupplierHierarchy sh ON rs.s_suppkey = sh.s_suppkey
WHERE (l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31')
AND (p.p_retailprice > 100 OR p.p_container IS NOT NULL)
AND l.l_returnflag IS NULL
GROUP BY p.p_name, r.r_name, c.c_name, sh.level, o.o_orderstatus
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY revenue DESC
LIMIT 10;
