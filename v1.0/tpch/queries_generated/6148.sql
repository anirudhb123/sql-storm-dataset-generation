WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost,
        n.n_name AS nation_name
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    WHERE rs.rank <= 3
),
CustomerOrderStats AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    ts.s_name,
    ts.nation_name,
    cos.c_name,
    cos.total_orders,
    cos.total_spent,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM TopSuppliers ts
JOIN lineitem l ON l.l_suppkey = ts.s_suppkey
JOIN CustomerOrderStats cos ON l.l_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey = cos.c_custkey
)
GROUP BY ts.s_name, ts.nation_name, cos.c_name, cos.total_orders, cos.total_spent
ORDER BY total_revenue DESC
LIMIT 10;
