WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_name
),
OrdersSummary AS (
    SELECT
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_revenue
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
)
SELECT
    r.region_name,
    rs.s_name,
    os.order_count,
    os.total_revenue,
    rs.total_supply_cost
FROM
    (SELECT r.r_name AS region_name, n.n_name AS nation_name
     FROM region r
     JOIN nation n ON r.r_regionkey = n.n_regionkey) AS r
JOIN
    RankedSuppliers rs ON r.nation_name = rs.nation_name
JOIN
    OrdersSummary os ON os.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = r.nation_name))
WHERE
    rs.supply_rank <= 3
ORDER BY
    r.region_name, rs.total_supply_cost DESC, os.total_revenue DESC;
