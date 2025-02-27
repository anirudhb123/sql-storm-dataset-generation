WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), 
OrderStats AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        n.n_name AS nation_name
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY o.o_orderkey, o.o_orderdate, n.n_name
), 
TopOrders AS (
    SELECT 
        o.*,
        ROW_NUMBER() OVER (PARTITION BY o.nation_name ORDER BY o.total_revenue DESC) AS order_rank
    FROM OrderStats o
    WHERE o.line_items > 5
)
SELECT 
    r.s_name,
    r.rank,
    t.o_orderkey,
    t.total_revenue,
    t.o_orderdate,
    t.nation_name
FROM RankedSuppliers r
JOIN TopOrders t ON r.s_suppkey IN (
    SELECT DISTINCT ps.ps_suppkey
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_orderkey = t.o_orderkey
)
WHERE r.rank <= 10
ORDER BY r.rank, t.total_revenue DESC;
