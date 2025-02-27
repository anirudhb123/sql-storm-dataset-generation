
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(o.o_totalprice) AS total_sales,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS region_rank
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01'
    GROUP BY 
        n.n_regionkey, r.r_name
),
TopPartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        SUM(ps.ps_supplycost) AS total_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS part_supplier_rank
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, p.p_name
)
SELECT 
    tr.r_name AS region_name,
    rs.s_name AS supplier_name,
    tp.p_name AS part_name,
    tp.total_cost,
    rs.total_supply_value AS supplier_total_value,
    tr.total_sales AS region_total_sales
FROM 
    TopRegions tr
JOIN 
    RankedSuppliers rs ON tr.n_regionkey = (SELECT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = rs.s_suppkey)
JOIN 
    TopPartSuppliers tp ON tp.supplier_count = (SELECT COUNT(DISTINCT ps.ps_suppkey) FROM partsupp ps WHERE ps.ps_partkey = tp.ps_partkey)
WHERE 
    rs.supplier_rank <= 5 
    AND tr.region_rank <= 5 
    AND tp.part_supplier_rank <= 5
ORDER BY 
    tr.total_sales DESC, rs.total_supply_value DESC, tp.total_cost DESC;
