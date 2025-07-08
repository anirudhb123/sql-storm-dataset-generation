
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supplycost,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS num_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationRegionStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    ss.s_name,
    ss.total_parts,
    ss.total_supplycost,
    ss.avg_acctbal,
    os.total_order_value,
    os.num_orders,
    nrs.region_name,
    nrs.supplier_count
FROM 
    SupplierStats ss
LEFT JOIN 
    OrderStats os ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#1') LIMIT 1)
JOIN 
    NationRegionStats nrs ON (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ss.s_suppkey) = nrs.n_nationkey
WHERE 
    ss.total_supplycost > 10000
ORDER BY 
    os.total_order_value DESC, ss.avg_acctbal ASC
FETCH FIRST 50 ROWS ONLY;
