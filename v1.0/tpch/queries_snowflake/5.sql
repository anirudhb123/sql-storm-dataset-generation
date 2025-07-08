
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS priority_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' (', s.s_phone, ')') AS supplier_info
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    sp.p_name,
    sp.supplier_info,
    co.c_name AS customer_name,
    co.total_orders,
    co.total_spent
FROM 
    RankedOrders ro
LEFT JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierParts sp ON l.l_partkey = sp.ps_partkey
LEFT JOIN 
    CustomerOrders co ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
WHERE 
    (sp.ps_supplycost IS NOT NULL OR sp.ps_availqty < 10)
    AND ro.priority_rank <= 3
ORDER BY 
    ro.o_orderdate DESC, co.total_orders DESC;
