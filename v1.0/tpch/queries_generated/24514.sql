WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
), SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
), NationalCustomer AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY c.c_acctbal DESC) AS rn
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    so.total_revenue,
    nc.nation_name
FROM 
    RankedParts rp
LEFT OUTER JOIN 
    SupplierOrders so ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 100)
LEFT JOIN 
    NationalCustomer nc ON nc.c_custkey IN (
        SELECT o.o_custkey 
        FROM orders o 
        WHERE o.o_orderstatus = 'O'
        HAVING SUM(l.l_quantity) > 50
        GROUP BY o.o_custkey
    )
WHERE 
    (nc.rn <= 5 AND so.total_revenue IS NOT NULL) 
   OR (rp.rn <= 10 AND rp.p_retailprice < ALL (SELECT p_retailprice FROM part WHERE p_size = 15))
ORDER BY 
    rp.p_brand, total_revenue DESC NULLS LAST;
