WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
), SupplierParts AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
), HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        (SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) 
         FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey) AS total_lineitem_value
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
), CombinedData AS (
    SELECT 
        hvo.o_orderkey,
        hvo.o_orderdate,
        hvo.o_totalprice,
        sp.s_suppkey,
        sp.p_partkey,
        sp.ps_supplycost,
        sp.ps_availqty,
        hvo.total_lineitem_value
    FROM 
        HighValueOrders hvo
    JOIN 
        SupplierParts sp ON hvo.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = hvo.o_orderkey)
)
SELECT 
    c.c_name AS customer_name,
    r.r_name AS region_name,
    CD.o_orderkey,
    CD.o_orderdate,
    CD.o_totalprice,
    CD.ps_supplycost,
    CD.ps_availqty,
    CD.total_lineitem_value
FROM 
    CombinedData CD
JOIN 
    customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = CD.o_orderkey)
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    CD.o_orderdate DESC, CD.o_totalprice DESC;
