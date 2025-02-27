WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 YEAR'
        AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
CustomerSegments AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_mktsegment
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 5
),
SupplierPrices AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    INNER JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    GROUP BY 
        ps.ps_suppkey
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price_after_discount,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count,
        AVG(l.l_quantity) AS average_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    cs.c_mktsegment,
    sp.total_supplycost,
    la.total_price_after_discount,
    la.return_count,
    la.average_quantity
FROM 
    RankedOrders r
LEFT JOIN 
    CustomerSegments cs ON r.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
LEFT JOIN 
    SupplierPrices sp ON sp.ps_suppkey IN (SELECT l.l_suppkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
LEFT JOIN 
    LineItemAnalysis la ON la.l_orderkey = r.o_orderkey
WHERE 
    (cs.order_count IS NULL OR sp.total_supplycost > 5000)
    AND r.order_rank <= 10
    AND (sp.total_supplycost IS NOT NULL OR la.return_count = 0)
ORDER BY 
    r.o_orderdate DESC, 
    total_price_after_discount DESC 
FETCH FIRST 20 ROWS ONLY;