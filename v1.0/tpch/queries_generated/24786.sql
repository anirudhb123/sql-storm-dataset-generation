WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100 AND 
        p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost < 50)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(month, -3, GETDATE())
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(os.total_revenue) AS total_order_revenue,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplier
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
LEFT JOIN 
    FilteredParts fp ON fp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey)
LEFT JOIN 
    OrderSummary os ON os.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = rs.s_suppkey)
WHERE 
    (n.n_name LIKE 'A%' OR n.n_name LIKE 'B%')
    AND (c.c_acctbal IS NULL OR c.c_acctbal > 3000)
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT rs.s_suppkey) > 5
ORDER BY 
    total_order_revenue DESC, n.n_name;
