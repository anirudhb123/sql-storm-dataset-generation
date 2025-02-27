WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
NationRegions AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    nw.n_name AS nation_name,
    nr.region_name,
    ss.s_name AS supplier_name,
    ss.total_available_quantity,
    ss.distinct_parts_supplied,
    ss.part_names,
    cast('1998-10-01' as date) AS benchmark_date
FROM SupplierStats ss
JOIN NationRegions nr ON ss.s_nationkey = nr.n_nationkey
JOIN nation nw ON nr.n_nationkey = nw.n_nationkey
WHERE ss.total_available_quantity > 1000
ORDER BY ss.total_available_quantity DESC;