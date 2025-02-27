WITH NationSupplier AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
), PartSupplier AS (
    SELECT p.p_name, SUM(ps.ps_availqty) AS total_available_quantity
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_name
), CustomerOrders AS (
    SELECT c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY c.c_name
), OrderLineItem AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT ns.n_name, ns.supplier_count, ps.p_name, ps.total_available_quantity, 
       co.c_name, co.total_orders, co.total_spent, oli.total_revenue
FROM NationSupplier ns
JOIN PartSupplier ps ON ps.total_available_quantity > 100
JOIN CustomerOrders co ON co.total_orders > 5
JOIN OrderLineItem oli ON oli.total_revenue > 5000
WHERE ns.supplier_count > 10
ORDER BY ns.n_name, co.total_spent DESC;
