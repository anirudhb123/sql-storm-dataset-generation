WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    WHERE 
        ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
    GROUP BY 
        ps.ps_partkey
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 5
),
TopRegions AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
    HAVING 
        COUNT(DISTINCT n.n_nationkey) > 2
)
SELECT 
    p.p_name,
    COALESCE(r.r_name, 'Unknown Region') AS region_name,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    h.total_cost,
    h.supplier_count,
    CASE 
        WHEN h.total_cost > 10000 THEN 'High Value'
        ELSE 'Low Value'
    END AS value_category
FROM 
    part p
LEFT JOIN 
    HighValueParts h ON p.p_partkey = h.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1 AND 
                           rs.s_suppkey IN (
                               SELECT ps.ps_suppkey 
                               FROM partsupp ps 
                               WHERE ps.ps_partkey = h.ps_partkey
                           )
LEFT JOIN 
    TopRegions r ON r.nation_count > 0 AND 
                   EXISTS (
                       SELECT 1
                       FROM supplier s 
                       WHERE s.s_nationkey IN (
                           SELECT n.n_nationkey 
                           FROM nation n 
                           WHERE n.n_regionkey IN (
                               SELECT r.r_regionkey 
                               FROM region
                           )
                       )
                   )
ORDER BY 
    p.p_name, region_name;
