WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
), RevenuePerSupplier AS (
    SELECT 
        ps.ps_suppkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        ps.ps_availqty > 0
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    r.r_name,
    COALESCE(SUM(rps.supplier_revenue), 0) AS total_supplier_revenue,
    COUNT(DISTINCT fo.o_orderkey) AS order_count,
    SUM(CASE WHEN fo.total_revenue > 1000 THEN 1 ELSE 0 END) AS high_value_orders,
    COUNT(DISTINCT CASE WHEN fcu.c_custkey IS NOT NULL THEN fcu.c_custkey END) AS unique_customers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer cu ON n.n_nationkey = cu.c_nationkey
LEFT JOIN 
    RankedOrders fo ON cu.c_custkey = fo.o_custkey
LEFT JOIN 
    RevenuePerSupplier rps ON rps.ps_suppkey = cu.c_nationkey
LEFT JOIN 
    FilteredSuppliers fcu ON fcu.s_suppkey = rps.ps_suppkey
WHERE 
    r.r_name IS NOT NULL OR r.r_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    total_supplier_revenue DESC;
