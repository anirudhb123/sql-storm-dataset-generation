WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_nationkey IN (SELECT DISTINCT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'N%')
        )
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (
            SELECT AVG(o2.o_totalprice) 
            FROM orders o2 
            WHERE o2.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
        )
)
SELECT
    e.p_partkey,
    e.p_name,
    COALESCE(e.s_name, 'No Supplier') AS supplier_name,
    e.o_orderkey,
    e.o_totalprice,
    e.NUM_STAFF,
    CUME_DIST() OVER (PARTITION BY e.p_partkey ORDER BY e.o_totalprice DESC) AS totalprice_percentile
FROM 
    (SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        CASE WHEN s.rn = 1 THEN 1 ELSE 0 END AS NUM_STAFF, 
        o.o_orderkey,
        o.o_totalprice
     FROM 
        part p
     LEFT JOIN 
        RankedSuppliers s ON p.p_partkey = s.p_partkey
     LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
     LEFT JOIN 
        HighValueOrders o ON l.l_orderkey = o.o_orderkey 
     WHERE 
        l.l_shipdate IS NOT NULL 
        AND (l.l_returnflag = 'Y' OR l.l_discount > 0.1)
    ) e
WHERE 
    e.o_totalprice < (SELECT MAX(o_totalprice) FROM HighValueOrders) OR e.o_orderkey IS NULL
ORDER BY
    e.p_partkey,
    e.o_totalprice DESC;
