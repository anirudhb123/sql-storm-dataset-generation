WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierParts AS (
    SELECT 
        ps.ps_supplierkey,
        p.p_partkey,
        p.p_brand,
        p.p_retailprice
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        ro.o_orderdate,
        ro.o_orderpriority,
        sp.p_partkey,
        sp.p_brand,
        sp.p_retailprice
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN 
        SupplierParts sp ON l.l_suppkey = sp.ps_supplierkey
    WHERE 
        ro.order_rank <= 10
)
SELECT 
    hvo.o_orderkey,
    hvo.o_totalprice,
    hvo.o_orderdate,
    hvo.o_orderpriority,
    COUNT(DISTINCT hvo.p_partkey) AS total_parts,
    SUM(hvo.p_retailprice) AS total_retail_price
FROM 
    HighValueOrders hvo
GROUP BY 
    hvo.o_orderkey, hvo.o_totalprice, hvo.o_orderdate, hvo.o_orderpriority
ORDER BY 
    hvo.o_totalprice DESC;
