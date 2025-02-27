WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        total_cost > 1000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 5000
)
SELECT 
    ns.n_name,
    hs.p_name,
    hs.p_retailprice,
    cs.total_orders,
    cs.total_spent,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name
FROM 
    HighValueParts hs
LEFT JOIN 
    RankedSuppliers rs ON hs.p_partkey = rs.s_suppkey
JOIN 
    nation ns ON rs.n_nationkey = ns.n_nationkey
JOIN 
    CustomerOrders cs ON cs.total_orders > 5
WHERE 
    (hs.p_retailprice > 50 OR cs.total_spent > 1000)
ORDER BY 
    ns.n_name, hs.p_retailprice DESC;
