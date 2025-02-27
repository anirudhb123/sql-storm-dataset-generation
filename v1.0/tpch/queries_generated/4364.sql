WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 50.00
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        CASE 
            WHEN r.r_name IS NULL THEN 'Unknown Region'
            ELSE r.r_name 
        END AS region_name
    FROM 
        customer c
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.c_custkey,
    cr.nation_name,
    cr.region_name,
    COALESCE(SUM(od.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
    AVG(rs.s_acctbal) AS avg_supplier_acctbal
FROM 
    CustomerRegion cr
LEFT JOIN 
    OrderDetails od ON cr.c_custkey = od.o_orderkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1
GROUP BY 
    cr.c_custkey, cr.nation_name, cr.region_name
HAVING 
    SUM(od.total_revenue) > 10000
ORDER BY 
    total_revenue DESC, supplier_count DESC;
