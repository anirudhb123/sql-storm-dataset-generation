WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
NationCustomerOrders AS (
    SELECT
        n.n_name,
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        nation n
    JOIN
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        n.n_name, c.c_custkey
)
SELECT
    r.r_name AS region,
    nco.n_name AS nation,
    nco.c_custkey,
    nco.order_count,
    nco.total_spent,
    rs.s_name AS top_supplier,
    rs.total_supply_cost
FROM
    RankedSuppliers rs
JOIN
    nation nco ON rs.s_nationkey = nco.n_nationkey
JOIN
    region r ON nco.n_regionkey = r.r_regionkey
ORDER BY
    r.r_name, nco.total_spent DESC, rs.total_supply_cost DESC
LIMIT 10;
