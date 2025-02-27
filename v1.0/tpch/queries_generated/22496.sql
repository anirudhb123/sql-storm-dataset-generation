WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderpriority
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
),
SupplierPart AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        ps.ps_availqty,
        COUNT(DISTINCT ps.ps_partkey) OVER (PARTITION BY s.s_suppkey) AS parts_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 100
)
SELECT 
    cn.nation_name,
    SUM(ro.total_revenue) AS total_revenue,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    COUNT(DISTINCT sp.s_suppkey) filter (WHERE sp.parts_count > 5) AS suppliers_with_multiple_parts
FROM 
    RankedOrders ro
LEFT JOIN 
    CustomerNation cn ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cn.c_custkey)
LEFT JOIN 
    SupplierPart sp ON sp.ps_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_acctbal > 150))
WHERE 
    ro.rnk = 1
GROUP BY 
    cn.nation_name
HAVING 
    SUM(ro.total_revenue) IS NOT NULL
ORDER BY 
    total_revenue DESC NULLS LAST;
