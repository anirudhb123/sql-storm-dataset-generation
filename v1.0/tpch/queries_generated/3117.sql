WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        n.n_name,
        SUM(od.total_revenue) AS region_revenue
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        n.n_regionkey, n.n_name
    HAVING 
        SUM(od.total_revenue) > (SELECT AVG(total_revenue) FROM OrderDetails)
)
SELECT 
    pr.p_partkey,
    pr.p_name,
    pr.p_brand,
    COALESCE(rs.s_name, 'No Supplier') AS best_supplier,
    rg.r_name AS region,
    tr.region_revenue
FROM 
    part pr
LEFT JOIN 
    RankedSuppliers rs ON pr.p_partkey = rs.ps_partkey AND rs.supplier_rank = 1
LEFT JOIN 
    partsupp ps ON pr.p_partkey = ps.ps_partkey
LEFT JOIN 
    TopRegions tr ON ps.ps_suppkey = tr.n_regionkey
LEFT JOIN 
    region rg ON tr.n_regionkey = rg.r_regionkey
WHERE 
    pr.p_retailprice > 1000
ORDER BY 
    region_revenue DESC NULLS LAST;
