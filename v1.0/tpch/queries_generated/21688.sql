WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
TotalOrderValue AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
    GROUP BY 
        o.o_orderkey
), 
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) IS NOT NULL
), 
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    ORDER BY 
        p.p_size DESC
    LIMIT 5
)

SELECT
    r.r_name,
    ts.p_name,
    ts.p_mfgr,
    COALESCE(ts.p_retailprice * sp.total_avail_qty, 0) AS projected_value,
    SUM(COALESCE(tov.total_value, 0)) AS order_total_value,
    (SELECT COUNT(*) 
        FROM customer c 
        WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000) AS valid_customers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
LEFT JOIN 
    TopParts ts ON sp.ps_partkey = ts.p_partkey
LEFT JOIN 
    TotalOrderValue tov ON tov.o_orderkey = (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
        ORDER BY o.o_orderdate DESC 
        LIMIT 1
    )
WHERE 
    r.r_regionkey IS NOT NULL
GROUP BY 
    r.r_name, ts.p_name, ts.p_mfgr, ts.p_retailprice
HAVING 
    SUM(COALESCE(tov.total_value, 0)) > 5000 
    OR COUNT(ts.p_partkey) > 0
ORDER BY 
    projected_value DESC NULLS LAST;
