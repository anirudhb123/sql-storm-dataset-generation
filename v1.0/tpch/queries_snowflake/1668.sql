
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
HighRevenueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.total_revenue,
        DENSE_RANK() OVER (ORDER BY o.total_revenue DESC) AS revenue_rank
    FROM 
        OrderStats o
    WHERE 
        o.total_revenue > (SELECT AVG(total_revenue) FROM OrderStats)
),
SupplierPartCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplying_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    r.r_name AS supplier_region,
    SUM(CASE WHEN ls.l_returnflag = 'Y' THEN 1 ELSE 0 END) AS return_count,
    COALESCE(sp.supplying_count, 0) AS supplier_count,
    s.s_name AS supplier_name
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    region r ON s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
LEFT JOIN 
    lineitem ls ON ls.l_partkey = p.p_partkey
LEFT JOIN 
    SupplierPartCounts sp ON sp.ps_partkey = p.p_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    p.p_partkey, p.p_name, r.r_name, s.s_name, sp.supplying_count
HAVING 
    COUNT(ls.l_orderkey) > 5 AND 
    r.r_name IS NOT NULL
ORDER BY 
    return_count DESC, p.p_name;
