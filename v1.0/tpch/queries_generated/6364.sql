WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        rs.nation_name,
        rs.s_name,
        rs.total_supply_value
    FROM RankedSuppliers rs
    JOIN nation n ON rs.nation_name = n.n_name
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.rank <= 5
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    ts.region_name,
    ts.nation_name,
    ts.s_name,
    os.c_name,
    os.order_count,
    os.total_spent,
    ts.total_supply_value
FROM TopSuppliers ts
JOIN OrderSummary os ON ts.total_supply_value > os.total_spent
ORDER BY ts.region_name, ts.nation_name, ts.total_supply_value DESC;
