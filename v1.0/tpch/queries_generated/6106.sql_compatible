
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name, 
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.nation_name,
    COUNT(DISTINCT r.s_suppkey) AS suppliers_count,
    COUNT(DISTINCT p.p_partkey) AS parts_count,
    SUM(o.total_revenue) AS total_revenue_last_year
FROM 
    RankedSuppliers r
JOIN 
    HighValueParts p ON p.total_value > 100000
JOIN 
    RecentOrders o ON o.o_orderkey IN (SELECT DISTINCT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
GROUP BY 
    r.nation_name
ORDER BY 
    total_revenue_last_year DESC;
