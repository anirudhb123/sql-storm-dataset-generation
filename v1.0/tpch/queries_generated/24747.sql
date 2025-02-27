WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        (CASE WHEN p.p_retailprice IS NULL THEN 'Unknown Price' ELSE CAST(p.p_retailprice AS varchar) END) AS serialized_price
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20 AND p.p_brand != 'BrandZ'
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    (
        SELECT 
            SUM(l.l_extendedprice * (1 - l.l_discount)) 
        FROM 
            lineitem l 
        WHERE 
            l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
    ) AS total_revenue,
    AVG(COALESCE(s.s_acctbal, 0)) AS avg_supplier_acctbal,
    CONCAT_WS(' - ', GROUP_CONCAT(DISTINCT pp.p_name), 'total parts') AS part_list
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey 
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey 
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey 
LEFT JOIN 
    FilteredParts pp ON pp.p_partkey IN (SELECT DISTINCT ps.ps_partkey FROM SupplierAvailability ps WHERE ps.max_supply_cost > 50)
WHERE 
    n.n_name IS NOT NULL 
GROUP BY 
    n.n_name
HAVING 
    total_orders > 10 AND avg_supplier_acctbal > 1000 
ORDER BY 
    total_revenue DESC
LIMIT 100;
