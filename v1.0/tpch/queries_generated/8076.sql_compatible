
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
    ORDER BY 
        total_availqty DESC
    LIMIT 10
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
    ORDER BY 
        total_supplycost DESC
    LIMIT 5
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1998-10-01' - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT 
    rp.p_name,
    tp.s_name,
    ro.total_revenue
FROM 
    RankedParts rp
JOIN 
    TopSuppliers tp ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = tp.s_suppkey)
JOIN 
    RecentOrders ro ON ro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = rp.p_partkey)
ORDER BY 
    ro.total_revenue DESC;
