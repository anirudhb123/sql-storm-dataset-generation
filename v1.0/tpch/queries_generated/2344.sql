WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s 
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        COUNT(n.n_nationkey) > 1
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
SupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        (ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        STRING_AGG(CASE WHEN s.s_name IS NOT NULL THEN s.s_name ELSE 'Unknown' END, ', ') AS supplier_names
    FROM 
        partsupp ps
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    s.total_supply_value,
    s.supplier_names,
    os.item_count,
    os.total_price,
    r.r_name AS region_name,
    rs.s_name AS top_supplier_name
FROM 
    part ps
LEFT JOIN 
    SupplierInfo s ON ps.p_partkey = s.ps_partkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey IN (SELECT o_orderkey FROM lineitem l WHERE l.l_partkey = ps.p_partkey)
LEFT JOIN 
    RankedSuppliers rs ON s.ps_suppkey = rs.s_suppkey AND rs.rank = 1
JOIN 
    TopRegions r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = s.ps_suppkey LIMIT 1)
WHERE 
    (s.total_supply_value IS NOT NULL OR s.total_supply_value > 10000)
ORDER BY 
    ps.p_partkey, os.total_price DESC;
