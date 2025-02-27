WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
TotalOrders AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.region_name,
    cr.nation_name,
    COUNT(DISTINCT cr.c_custkey) AS customer_count,
    COALESCE(SUM(tr.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count
FROM 
    CustomerRegions cr
LEFT JOIN 
    TotalOrders tr ON cr.c_custkey = tr.o_custkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey from part p WHERE p.p_size > 15))
GROUP BY 
    cr.region_name, cr.nation_name
HAVING 
    SUM(tr.total_revenue) > 5000 OR COUNT(DISTINCT rs.s_suppkey) > 5
ORDER BY 
    total_revenue DESC, customer_count DESC;
