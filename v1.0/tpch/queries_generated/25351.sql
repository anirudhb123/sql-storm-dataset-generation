WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY COUNT(ps.ps_partkey) DESC, SUM(ps.ps_supplycost) ASC) AS rn
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT
        rs.s_suppkey,
        rs.s_name,
        rs.nation_name,
        rs.part_count,
        rs.total_supply_cost
    FROM
        RankedSuppliers rs
    WHERE
        rs.rn <= 5
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT
    ts.s_name AS supplier_name,
    ts.nation_name,
    co.c_name AS customer_name,
    co.o_orderkey,
    co.o_orderdate,
    co.o_totalprice,
    co.lineitem_count,
    CONCAT('Supplier ', ts.s_name, ' from ', ts.nation_name, ' supplied ', co.lineitem_count, ' items for order ', co.o_orderkey) AS order_summary
FROM
    TopSuppliers ts
JOIN
    CustomerOrders co ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE LENGTH(p.p_name) > 30) LIMIT 1)
ORDER BY
    ts.nation_name, co.o_orderdate DESC;
