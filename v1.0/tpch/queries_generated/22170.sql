WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS ranking
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size BETWEEN 1 AND (SELECT MAX(p_size) FROM part WHERE p_comment LIKE '%quality%')
    GROUP BY 
        p.p_partkey, p.p_name, p.p_type
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        o.o_orderkey,
        o.o_totalprice,
        NTILE(5) OVER (ORDER BY o.o_totalprice DESC) AS order_bucket
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
)
SELECT 
    fp.p_name,
    fp.p_type,
    cs.c_custkey,
    SUM(cs.o_totalprice) AS total_order_value,
    COUNT(DISTINCT rs.s_suppkey) AS distinct_suppliers,
    SUM(COALESCE(fp.total_supply_cost, 0)) AS aggregated_supply_cost
FROM 
    FilteredParts fp
LEFT JOIN 
    SupplierParts sp ON fp.p_partkey = sp.ps_partkey
FULL OUTER JOIN 
    CustomerOrders cs ON fp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM RankedSuppliers rs WHERE rs.ranking <= 3))
WHERE 
    cs.o_orderkey IS NULL OR cs.order_bucket IN (1, 5)
GROUP BY 
    fp.p_name, fp.p_type, cs.c_custkey
HAVING 
    SUM(cs.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
    AND COUNT(DISTINCT cs.o_orderkey) > 1
ORDER BY 
    total_order_value DESC, aggregated_supply_cost ASC;
