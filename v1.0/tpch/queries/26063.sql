WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
), 
TopSuppliers AS (
    SELECT
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_suppkey,
        rs.s_name,
        rs.total_avail_qty,
        rs.total_supply_cost
    FROM
        RankedSuppliers rs
    JOIN
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        rs.rank <= 3
)
SELECT
    region_name,
    nation_name,
    STRING_AGG(s_name || ' (Available Qty: ' || total_avail_qty || ', Supply Cost: ' || total_supply_cost || ')', '; ') AS suppliers_info
FROM
    TopSuppliers
GROUP BY
    region_name, nation_name
ORDER BY
    region_name, nation_name;
