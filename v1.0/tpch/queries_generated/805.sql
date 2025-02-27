WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_suppkey
), 
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
)
SELECT 
    n.n_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(COALESCE(ts.total_revenue, 0)) AS total_revenue_by_nation,
    AVG(COALESCE(ts.total_revenue, 0)) AS avg_revenue_per_supplier,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    RankedSuppliers s
LEFT JOIN 
    TotalSales ts ON s.s_suppkey = ts.l_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    FilteredOrders o ON s.s_suppkey IN (SELECT ps.s_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey))
WHERE 
    s.supplier_rank = 1
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue_by_nation DESC;
