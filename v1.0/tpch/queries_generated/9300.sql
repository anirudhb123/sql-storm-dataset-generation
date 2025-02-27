WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT
        r.r_name,
        ns.n_name,
        ts.s_suppkey,
        ts.s_name,
        ts.total_supply_value
    FROM RankedSuppliers ts
    JOIN nation ns ON ts.s_nationkey = ns.n_nationkey
    JOIN region r ON ns.n_regionkey = r.r_regionkey
    WHERE ts.rank <= 10
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT
    ts.r_name AS region_name,
    ts.n_name AS nation_name,
    ts.s_suppkey,
    ts.s_name,
    co.c_custkey,
    co.c_name,
    co.total_order_value
FROM TopSuppliers ts
JOIN CustomerOrders co ON ts.total_supply_value > co.total_order_value
ORDER BY ts.r_name, ts.n_name, ts.total_supply_value DESC, co.total_order_value DESC;
