WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT rs.s_suppkey, rs.s_name, rs.total_cost, RANK() OVER (PARTITION BY rs.s_nationkey ORDER BY rs.total_cost DESC) AS rank
    FROM RankedSuppliers rs
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, o.o_orderpriority
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '2023-01-01' -- Filtering active orders for the current year
)
SELECT 
    co.c_custkey,
    co.c_name,
    COUNT(co.o_orderkey) AS total_orders,
    SUM(co.o_totalprice) AS total_spent,
    ns.n_name AS nation_name,
    ts.s_name AS top_supplier_name,
    ts.total_cost AS top_supplier_cost
FROM CustomerOrders co
JOIN nation ns ON co.o_orderkey IN (SELECT l.o_orderkey FROM lineitem l WHERE l.l_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#12'))
JOIN TopSuppliers ts ON ns.n_nationkey = ts.s_nationkey AND ts.rank = 1
GROUP BY co.c_custkey, co.c_name, ns.n_name, ts.s_name, ts.total_cost
ORDER BY total_spent DESC
LIMIT 100; -- Limit to the top 100 customers by total spent
