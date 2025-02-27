WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 500
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderstatus,
    sp.total_supplycost,
    co.order_count,
    co.total_spent
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierParts sp ON sp.total_supplycost = (
        SELECT MAX(total_supplycost) 
        FROM SupplierParts WHERE p_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
    )
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = r.o_orderkey)
WHERE 
    r.rnk = 1
ORDER BY 
    r.o_orderdate DESC, r.o_orderkey
LIMIT 100;