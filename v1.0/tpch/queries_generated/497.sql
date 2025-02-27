WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        total_supplycost > 10000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        COALESCE(AVG(ps.ps_availqty), 0) AS avg_avail_qty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_mktsegment,
    p.p_name,
    pd.supplier_count,
    pd.avg_avail_qty,
    hs.s_name,
    hs.total_supplycost
FROM 
    RankedOrders r
JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
JOIN 
    PartDetails pd ON l.l_partkey = pd.p_partkey
LEFT JOIN 
    HighValueSuppliers hs ON pd.supplier_count > 1 AND hs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = pd.p_partkey
    )
WHERE 
    r.rn <= 5
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
