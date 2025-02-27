WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
), CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
), SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100
)
SELECT 
    c.c_name,
    COALESCE(cp.total_spent, 0) AS total_spent,
    sp.p_name,
    SUM(sp.ps_availqty) AS total_available
FROM 
    CustomerPurchases cp
FULL OUTER JOIN 
    SupplierParts sp ON cp.c_custkey = sp.s_suppkey
JOIN 
    RankedOrders ro ON cp.total_spent > 10000 AND ro.o_orderkey = cp.c_custkey
WHERE 
    sp.p_name LIKE '%widget%'
GROUP BY 
    c.c_name, cp.total_spent, sp.p_name
HAVING 
    SUM(sp.ps_availqty) IS NOT NULL
ORDER BY 
    total_spent DESC, total_available DESC;
