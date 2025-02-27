WITH RECURSIVE RegionalSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, r.r_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name NOT LIKE 'A%' AND s.s_acctbal > 1000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, r.r_name
    FROM supplier s
    JOIN RegionalSuppliers rs ON s.s_nationkey = rs.s_nationkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name NOT LIKE 'A%' AND s.s_acctbal < rs.s_acctbal
),

ProductAvailability AS (
    SELECT p.p_partkey, p.p_name, COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING total_avail_qty > 0
),

OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_extendedprice) AS sum_extendedprice,
           COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice
)

SELECT r.r_name, p.p_name, av.total_avail_qty, COUNT(DISTINCT od.o_orderkey) AS order_count,
       SUM(od.sum_extendedprice) AS total_sales
FROM RegionalSuppliers r
JOIN ProductAvailability av ON av.total_avail_qty < 100
JOIN lineitem l ON l.l_suppkey = r.s_suppkey
JOIN OrderDetails od ON od.o_orderkey = l.l_orderkey
WHERE r.s_acctbal BETWEEN 1000 AND 5000
GROUP BY r.r_name, p.p_name, av.total_avail_qty
HAVING COUNT(DISTINCT od.unique_customers) > 10 
   AND SUM(od.sum_extendedprice) / COUNT(DISTINCT od.o_orderkey) > 500
ORDER BY total_sales DESC
LIMIT 5;
