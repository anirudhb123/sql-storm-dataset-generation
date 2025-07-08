WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_region
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT
        r.r_name AS region_name,
        COUNT(DISTINCT rs.s_suppkey) AS top_supplier_count,
        SUM(rs.total_supply_cost) AS total_region_supply_cost
    FROM
        RankedSuppliers rs
    JOIN
        nation n ON rs.nation_name = n.n_name
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        rs.rank_within_region <= 5 
    GROUP BY
        r.r_name
)
SELECT
    ts.region_name,
    ts.top_supplier_count,
    ts.total_region_supply_cost,
    AVG(o.o_totalprice) AS avg_order_total
FROM
    TopSuppliers ts
JOIN
    customer c ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = ts.region_name)
JOIN
    orders o ON o.o_custkey = c.c_custkey
GROUP BY
    ts.region_name, ts.top_supplier_count, ts.total_region_supply_cost
ORDER BY
    ts.total_region_supply_cost DESC;