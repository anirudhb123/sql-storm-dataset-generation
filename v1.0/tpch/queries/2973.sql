
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.supplier_count,
        ps.total_supplycost
    FROM 
        part p
    JOIN 
        SupplierStats ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
        OR ps.total_supplycost > 1000
),
FinalReport AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.c_name,
        hvp.p_name,
        hvp.p_retailprice
    FROM 
        RankedOrders ro
    LEFT JOIN 
        HighValueParts hvp ON ro.o_orderkey IN (
            SELECT l.l_orderkey
            FROM lineitem l
            WHERE l.l_partkey = hvp.p_partkey
        )
    WHERE 
        ro.rn <= 5
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.c_name,
    COALESCE(f.p_name, 'No High Value Part') AS part_name,
    COALESCE(f.p_retailprice, 0) AS retail_price
FROM 
    FinalReport f
ORDER BY 
    f.o_orderdate DESC, 
    f.c_name;
