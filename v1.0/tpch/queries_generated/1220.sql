WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
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
        l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey
),
SupplierPartCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(su.s_name, 'No Supplier') AS supplier_name,
    COALESCE(oh.total_revenue, 0) AS overall_revenue,
    r.r_name AS region_name,
    CASE 
        WHEN sp.supplier_count > 5 THEN 'High Supply' 
        ELSE 'Low Supply' 
    END AS supply_status
FROM 
    part p
LEFT JOIN 
    (SELECT * FROM RankedSuppliers WHERE rnk = 1) su ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = su.s_suppkey)
LEFT JOIN 
    OrderDetails oh ON p.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = oh.o_orderkey)
LEFT JOIN 
    supplier s ON s.s_suppkey = su.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierPartCounts sp ON p.p_partkey = sp.ps_partkey
WHERE 
    p.p_retailprice > 100.00
ORDER BY 
    overall_revenue DESC NULLS LAST;
