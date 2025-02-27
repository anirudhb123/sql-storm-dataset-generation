WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           DENSE_RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
), CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, ROW_NUMBER() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
)
SELECT p.p_partkey, p.p_name, p.p_brand, 
       rs.s_name AS top_supplier, 
       c.c_name AS customer_name, 
       COUNT(DISTINCT l.l_orderkey) AS order_count, 
       SUM(l.l_extendedprice) AS total_revenue,
       COUNT(DISTINCT h.order_rank) AS high_value_order_count
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.supplier_rank = 1
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN CustomerOrderStats c ON o.o_custkey = c.c_custkey
JOIN HighValueOrders h ON o.o_orderkey = h.o_orderkey
WHERE p.p_size > 10 AND o.o_orderdate < CURRENT_DATE
GROUP BY p.p_partkey, p.p_name, p.p_brand, rs.s_name, c.c_name
HAVING SUM(l.l_extendedprice) > 100000
ORDER BY total_revenue DESC;
