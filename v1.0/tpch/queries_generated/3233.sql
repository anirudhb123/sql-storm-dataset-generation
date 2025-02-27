WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
AggregatedRevenue AS (
    SELECT 
        c.c_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND 
        o.o_orderdate < '2024-01-01'
    GROUP BY 
        c.c_custkey
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(SUM(ar.total_revenue), 0) AS total_revenue,
    COALESCE(SUM(sa.total_available), 0) AS total_availability,
    MAX(rs.s_name) AS top_supplier_name
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    AggregatedRevenue ar ON c.c_custkey = ar.c_custkey
LEFT JOIN 
    SupplierAvailability sa ON sa.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_mfgr = 'ManufacturerA')
LEFT JOIN 
    RankedSuppliers rs ON rs.rank = 1 AND n.n_nationkey = (SELECT MAX(n2.n_nationkey) FROM nation n2 WHERE n2.n_name = n.n_name)
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC, 
    total_availability DESC
LIMIT 10;
