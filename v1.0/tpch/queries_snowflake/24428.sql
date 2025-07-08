
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
        s.s_nationkey
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL 
        AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATEADD(year, -1, '1998-10-01')
    GROUP BY 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderdate
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        p.p_brand,
        SUM(ps.ps_availqty) AS total_availability
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_brand
)
SELECT 
    n.n_name,
    COUNT(DISTINCT CASE WHEN rs.rank <= 3 THEN rs.s_suppkey END) AS top_suppliers_count,
    SUM(ro.total_revenue) AS total_revenue,
    LISTAGG(DISTINCT CONCAT(sp.p_brand, ', ', sp.total_availability), '; ') AS brand_availabilities
FROM 
    RankedSuppliers rs
LEFT OUTER JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
LEFT JOIN 
    RecentOrders ro ON ro.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
LEFT JOIN 
    SupplierParts sp ON sp.ps_suppkey = rs.s_suppkey
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT rs.s_suppkey) > 0 
    AND SUM(ro.total_revenue) IS NOT NULL
ORDER BY 
    top_suppliers_count DESC, total_revenue DESC
LIMIT 10;
