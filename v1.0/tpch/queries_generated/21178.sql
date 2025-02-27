WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 0
),
CustomerOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_custkey
)
SELECT 
    c.c_custkey,
    c.c_name,
    COALESCE(c.total_spent, 0) AS total_spent,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier,
    COUNT(DISTINCT l.l_orderkey) AS distinct_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
    COUNT(p.p_partkey) AS popular_parts_count
FROM 
    customer c
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.o_custkey
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    partsupp ps ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    SupplierInfo s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    RankedParts p ON p.p_partkey = ps.ps_partkey AND p.rn = 1
WHERE 
    c.c_acctbal IS NOT NULL
GROUP BY 
    c.c_custkey, c.c_name, s.s_name
HAVING 
    SUM(l.l_quantity) > 
    (SELECT AVG(l2.l_quantity) FROM lineitem l2 WHERE l2.l_returnflag = 'R') 
    OR COUNT(DISTINCT l.l_orderkey) = 0
ORDER BY 
    total_spent DESC, c.c_name
OPTION (MAXDOP 1);
