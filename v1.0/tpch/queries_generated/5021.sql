WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_regionkey
),
TopSuppliers AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        COUNT(*) AS top_supplier_count
    FROM
        region r
    JOIN
        RankedSuppliers rs ON r.r_regionkey = rs.s_nationkey
    WHERE
        rs.supplier_rank <= 5
    GROUP BY
        r.r_regionkey, r.r_name
)
SELECT
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_net_price
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
JOIN
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    r.r_regionkey IN (SELECT r_regionkey FROM TopSuppliers)
GROUP BY
    r.r_name
ORDER BY
    total_revenue DESC
LIMIT 10;
