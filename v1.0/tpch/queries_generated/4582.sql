WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_name AS supplier_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        p.p_name,
        sp.supplier_name,
        sp.total_available,
        ROW_NUMBER() OVER (PARTITION BY p.p_name ORDER BY sp.total_available DESC) AS supplier_rank
    FROM 
        part p
    JOIN 
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_mktsegment,
    tsp.p_name,
    tsp.supplier_name,
    tsp.total_available
FROM 
    RankedOrders ro
LEFT JOIN 
    TopSuppliers tsp ON ro.o_orderkey = (SELECT l.l_orderkey 
                                          FROM lineitem l 
                                          WHERE l.l_orderkey = ro.o_orderkey 
                                          ORDER BY l.l_extendedprice DESC 
                                          LIMIT 1)
WHERE 
    tsp.supplier_rank = 1
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
