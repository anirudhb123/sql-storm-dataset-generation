WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING COUNT(DISTINCT ps.ps_partkey) > 10
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
), DetailedLineItems AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
    FROM lineitem li
    JOIN orders o ON li.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY li.l_orderkey
)
SELECT 
    s.s_suppkey, 
    s.s_name, 
    ts.parts_supplied, 
    co.order_count, 
    co.total_spent, 
    COUNT(dli.l_orderkey) AS completed_orders,
    SUM(dli.revenue) AS total_revenue
FROM TopSuppliers ts
JOIN supplier s ON ts.s_suppkey = s.s_suppkey
JOIN CustomerOrders co ON EXISTS (
    SELECT 1 
    FROM partsupp ps
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    WHERE ps.ps_suppkey = s.s_suppkey AND li.l_orderkey IN (
        SELECT l_orderkey FROM orders WHERE o_custkey IN (
            SELECT c_custkey FROM customer WHERE c_name = co.c_name
        )
    )
)
JOIN DetailedLineItems dli ON dli.l_orderkey IN (
    SELECT o_orderkey FROM orders WHERE o_custkey IN (
        SELECT c_custkey FROM customer WHERE c_name = co.c_name
    )
)
GROUP BY s.s_suppkey, s.s_name, ts.parts_supplied, co.order_count, co.total_spent
ORDER BY total_revenue DESC, co.order_count DESC;
