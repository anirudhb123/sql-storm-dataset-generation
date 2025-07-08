
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_retailprice,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY p.p_retailprice DESC) AS part_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        sp.s_suppkey,
        sp.p_partkey,
        sp.p_retailprice
    FROM 
        RankedOrders ro
    LEFT JOIN 
        lineitem li ON ro.o_orderkey = li.l_orderkey
    LEFT JOIN 
        SupplierParts sp ON li.l_partkey = sp.p_partkey
    WHERE 
        ro.price_rank = 1 AND sp.part_rank <= 5
)
SELECT 
    hvo.o_orderkey,
    hvo.o_totalprice,
    COALESCE(AVG(hvo.p_retailprice), 0) AS avg_part_price,
    COUNT(DISTINCT hvo.s_suppkey) AS unique_suppliers,
    CASE 
        WHEN COUNT(hvo.s_suppkey) = 0 THEN 'No Supplier'
        ELSE 'Suppliers Available'
    END AS supplier_status
FROM 
    HighValueOrders hvo
GROUP BY 
    hvo.o_orderkey, hvo.o_totalprice
HAVING 
    SUM(hvo.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'O')
ORDER BY 
    hvo.o_totalprice DESC
LIMIT 10 OFFSET (SELECT COUNT(DISTINCT o_orderkey) FROM orders) / 10;
