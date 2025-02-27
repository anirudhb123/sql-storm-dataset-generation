WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ntile(3) OVER (ORDER BY p.p_retailprice DESC) AS price_tier
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) 
            FROM part p2
        )
),
LargeOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
),
SupplierPartStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    np.n_name,
    p.p_name,
    COALESCE(sp.supplier_count, 0) AS supplier_count,
    r.rank_acctbal,
    hpp.price_tier,
    l.total_revenue,
    CASE 
        WHEN l.total_revenue IS NULL THEN 'No Large Orders'
        ELSE 'Large Order Exists'
    END AS order_status
FROM 
    nation np
LEFT JOIN 
    RankedSuppliers r ON np.n_nationkey = r.s_suppkey
INNER JOIN 
    HighValueParts hpp ON hpp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = r.s_suppkey)
LEFT JOIN 
    SupplierPartStats sp ON hpp.p_partkey = sp.ps_partkey
LEFT JOIN 
    LargeOrders l ON l.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = np.n_nationkey))
WHERE 
    r.rank_acctbal <= 3
ORDER BY 
    np.n_name, p.p_name;
