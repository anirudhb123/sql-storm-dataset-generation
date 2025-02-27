WITH supplier_parts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' supplies ', p.p_name) AS supply_info
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
),
nation_suppliers AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT sp.s_suppkey) AS supplier_count,
        STRING_AGG(sp.supply_info, '; ') AS supply_details
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        supplier_parts sp ON s.s_suppkey = sp.s_suppkey
    GROUP BY
        n.n_nationkey,
        n.n_name
)
SELECT
    r.r_name AS region,
    ns.n_name AS nation,
    ns.supplier_count,
    ns.supply_details
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
JOIN
    nation_suppliers ns ON n.n_nationkey = ns.n_nationkey
ORDER BY
    r.r_name, ns.n_name;
