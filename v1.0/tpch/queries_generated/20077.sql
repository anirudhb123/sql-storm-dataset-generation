WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rank_totalprice
    FROM 
        orders o
    WHERE 
        o.o_orderdate > (SELECT MAX(l.l_shipdate) FROM lineitem l)
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 1
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(s.total_supplycost, 0) AS total_supplycost,
    COALESCE(c.total_spent, 0) AS total_spent,
    o.o_orderdate,
    o.rank_totalprice
FROM 
    part p
LEFT JOIN 
    SupplierParts s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = (SELECT MAX(o2.o_orderkey) 
                                        FROM orders o2 
                                        WHERE o2.o_orderdate <= o.o_orderdate)
LEFT JOIN 
    CustomerStats c ON p.p_partkey = (SELECT ps.ps_partkey 
                                        FROM partsupp ps 
                                        WHERE ps.ps_supplycost = 0 
                                        AND ps.ps_availqty IS NOT NULL 
                                        LIMIT 1)
WHERE 
    p.p_size IN (SELECT DISTINCT p_inner.p_size 
                  FROM part p_inner 
                  WHERE p_inner.p_retailprice BETWEEN 10.00 AND 100.00)
    AND p.p_comment IS NOT NULL 
    AND s.supplier_count IS NOT NULL 
ORDER BY 
    total_spent DESC, total_supplycost ASC;
