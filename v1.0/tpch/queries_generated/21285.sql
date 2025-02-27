WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), 
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 20.00 
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000.00
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        COUNT(l.l_orderkey) > 5
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        COALESCE(ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC), 0) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    SUM(COALESCE(hp.total_value, 0)) AS total_parts_value,
    AVG(co.line_count) AS avg_line_count,
    STRING_AGG(DISTINCT cs.c_name) AS customer_names,
    MAX(CASE WHEN cs.order_rank = 1 THEN COALESCE(co.o_orderkey, 'N/A') END) AS last_order_key
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_suppkey
LEFT JOIN 
    HighValueParts hp ON hp.p_partkey = rs.s_suppkey
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey = hp.p_partkey
LEFT JOIN 
    RecentOrders ro ON co.o_orderkey = ro.o_orderkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT rs.s_suppkey) > 5
ORDER BY 
    total_parts_value DESC NULLS LAST;
