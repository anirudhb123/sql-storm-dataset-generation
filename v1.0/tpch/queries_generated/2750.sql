WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    coalesce(SUM(co.total_spent), 0) AS total_customer_spent,
    r.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_suppkey = l.l_suppkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rn = 1
LEFT JOIN 
    nation n ON rs.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrders co ON co.order_count > 10
GROUP BY 
    p.p_partkey, p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 2 AND SUM(l.l_extendedprice * (1 - l.l_discount)) > 500
ORDER BY 
    total_revenue DESC, p.p_name ASC;
