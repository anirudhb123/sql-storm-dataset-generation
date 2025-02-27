WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 1000
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
), TopProducts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN part p ON l.l_partkey = p.p_partkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    tp.p_name, 
    rs.s_name AS top_supplier, 
    tp.total_sales, 
    co.order_count
FROM TopProducts tp
JOIN RankedSuppliers rs ON rs.rnk = 1 AND rs.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey = tp.p_partkey
)
JOIN CustomerOrders co ON co.order_count > 10
ORDER BY tp.total_sales DESC, co.order_count DESC
LIMIT 10;
