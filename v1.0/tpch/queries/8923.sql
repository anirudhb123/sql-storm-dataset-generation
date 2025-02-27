WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM
        supplier s
),
HighBalanceCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        c.c_nationkey
    FROM
        customer c
    WHERE
        c.c_acctbal > 50000
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        l.l_quantity,
        l.l_discount,
        l.l_tax
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderdate < DATE '1997-10-01'
),
SupplierPerformance AS (
    SELECT
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_suppkey
)
SELECT
    ns.n_name AS nation_name,
    rs.s_name AS supplier_name,
    hbc.c_name AS customer_name,
    SUM(od.o_totalprice) AS total_order_value,
    SUM(sp.total_supply_cost) AS total_supply_cost
FROM
    RankedSuppliers rs
JOIN
    nation ns ON rs.s_nationkey = ns.n_nationkey
JOIN
    HighBalanceCustomers hbc ON hbc.c_nationkey = ns.n_nationkey
JOIN
    OrderDetails od ON od.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_custkey = hbc.c_custkey
    )
JOIN
    SupplierPerformance sp ON sp.ps_suppkey = rs.s_suppkey
WHERE
    rs.rank_acctbal <= 5
GROUP BY
    ns.n_name, rs.s_name, hbc.c_name
ORDER BY
    nation_name, total_order_value DESC;