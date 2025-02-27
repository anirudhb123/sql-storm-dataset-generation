
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation,
        r.r_name AS region
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        cr.nation,
        cr.region,
        COALESCE(SUBSTRING(cr.nation, 1, 1) || ' High', 'Unknown') AS nation_high
    FROM 
        RankedOrders ro
    LEFT JOIN 
        CustomerRegion cr ON ro.o_orderkey = (
            SELECT MIN(c.c_custkey) 
            FROM customer c 
            WHERE c.c_custkey = ro.o_orderkey
        )
    WHERE 
        ro.rank <= 5
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    sp.total_availqty,
    sp.total_supplycost,
    hvo.nation_high
FROM 
    HighValueOrders hvo
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey IN (
        SELECT 
            l.l_partkey
        FROM 
            lineitem l
        WHERE 
            l.l_orderkey = hvo.o_orderkey
            AND l.l_discount BETWEEN 0.1 AND 0.5
    )
WHERE 
    EXISTS (
        SELECT 1 
        FROM supplier s 
        WHERE 
            s.s_suppkey = sp.ps_suppkey 
            AND s.s_acctbal >= (
                SELECT AVG(s2.s_acctbal)
                FROM supplier s2
            )
    )
ORDER BY 
    hvo.o_orderdate DESC, 
    hvo.o_totalprice DESC
LIMIT 10 OFFSET 5;
