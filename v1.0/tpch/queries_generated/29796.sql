WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        COUNT(ps.ps_partkey) AS part_count,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(ps.ps_partkey) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        n.n_name AS nation_name,
        rs.part_count
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        rs.rank_within_nation <= 3
), SupplierDetails AS (
    SELECT 
        fs.s_suppkey,
        fs.s_name,
        fs.nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        STRING_AGG(DISTINCT p.p_name, ', ') AS supplied_parts
    FROM 
        FilteredSuppliers fs
    JOIN 
        partsupp ps ON fs.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        fs.s_suppkey, fs.s_name, fs.nation_name
)
SELECT 
    sd.s_suppkey,
    sd.s_name,
    sd.nation_name,
    sd.total_revenue,
    sd.total_orders,
    sd.supplied_parts
FROM 
    SupplierDetails sd
ORDER BY 
    sd.total_revenue DESC;
