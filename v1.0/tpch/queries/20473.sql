
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
NationTotals AS (
    SELECT 
        n.n_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1990-01-01' AND 
        o.o_orderdate < DATE '1991-01-01'
    GROUP BY 
        n.n_nationkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 0
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unspecified'
            WHEN p.p_size <= 10 THEN 'Small'
            WHEN p.p_size BETWEEN 11 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice BETWEEN 100 AND 500
),
TopRegions AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        COUNT(n.n_nationkey) > 1
)
SELECT 
    fr.r_regionkey,
    fr.r_name,
    SUM(pt.total_revenue) AS total_revenue,
    STRING_AGG(DISTINCT CONCAT('Supplier: ', rs.s_name, ' (Balance: ', rs.s_acctbal, ')'), '; ') AS suppliers_info,
    COUNT(DISTINCT fp.p_partkey) AS part_count,
    CASE 
        WHEN SUM(pt.total_revenue) IS NULL THEN 'No Revenue'
        ELSE 'Revenue Exists'
    END AS revenue_status
FROM 
    TopRegions fr
LEFT JOIN 
    NationTotals pt ON fr.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = pt.n_nationkey)
LEFT JOIN 
    RankedSuppliers rs ON rs.rnk <= 3
LEFT JOIN 
    FilteredParts fp ON fp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey)
GROUP BY 
    fr.r_regionkey, fr.r_name
ORDER BY 
    total_revenue DESC NULLS LAST;
