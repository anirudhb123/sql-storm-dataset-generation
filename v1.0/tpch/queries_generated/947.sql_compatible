
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
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_returned,
    COALESCE(AVG(l.l_extendedprice * (1 - l.l_discount)), 0) AS avg_net_price,
    cs.c_name AS customer_name,
    rs.s_name AS supplier_name,
    rs.s_acctbal AS supplier_balance
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier rs ON ps.ps_suppkey = rs.s_suppkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    CustomerOrders cs ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
WHERE 
    p.p_retailprice BETWEEN 10.00 AND 100.00
    AND EXISTS (
        SELECT 1 
        FROM region r 
        WHERE r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = rs.s_nationkey) 
        AND r.r_name = 'ASIA'
    )
GROUP BY 
    p.p_name, p.p_brand, cs.c_name, rs.s_name, rs.s_acctbal
HAVING 
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) > 5 
ORDER BY 
    avg_net_price DESC, total_returned ASC;
