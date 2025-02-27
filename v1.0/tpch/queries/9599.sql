WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_availqty) AS total_avail_qty, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) as rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
TopSuppliers AS (
    SELECT * FROM RankedSuppliers WHERE rank <= 3
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT cs.c_custkey, cs.c_name, COUNT(co.o_orderkey) AS total_orders, 
       SUM(co.order_value) AS total_order_value, ts.s_name AS top_supplier_name
FROM CustomerOrders co
JOIN customer cs ON co.c_custkey = cs.c_custkey
JOIN TopSuppliers ts ON co.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = ts.s_suppkey)
GROUP BY cs.c_custkey, cs.c_name, ts.s_name
HAVING SUM(co.order_value) > 10000
ORDER BY total_order_value DESC;
