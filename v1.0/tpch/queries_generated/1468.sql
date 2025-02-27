WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000.00
),
TotalRevenue AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_custkey
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(tr.total_revenue, 0) AS total_revenue,
        CASE 
            WHEN COALESCE(tr.total_revenue, 0) > 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM 
        customer c
    LEFT JOIN 
        TotalRevenue tr ON c.c_custkey = tr.o_custkey
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_supplycost,
        COALESCE(rn.rn, 0) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        RankedSuppliers rn ON ps.ps_suppkey = rn.s_suppkey
)
SELECT 
    cd.c_custkey,
    cd.c_name,
    sp.p_name,
    sp.p_retailprice,
    sp.ps_supplycost,
    cd.total_revenue,
    cd.customer_type,
    ROW_NUMBER() OVER (PARTITION BY cd.customer_type ORDER BY cd.total_revenue DESC) AS customer_ranking
FROM 
    CustomerDetails cd
JOIN 
    SupplierParts sp ON sp.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_supplycost < 50)
WHERE 
    cd.total_revenue > (SELECT AVG(total_revenue) FROM TotalRevenue)
ORDER BY 
    cd.customer_type, cd.total_revenue DESC;
