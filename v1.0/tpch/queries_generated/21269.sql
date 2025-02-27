WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS acct_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey
        )
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
), HighlyRatedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) as price_rank
    FROM 
        part p
    WHERE 
        EXISTS (
            SELECT 1 
            FROM partsupp ps 
            WHERE ps.ps_partkey = p.p_partkey 
              AND ps.ps_availqty > (
                  SELECT AVG(ps2.ps_availqty) FROM partsupp ps2 WHERE ps2.ps_partkey = p.p_partkey
              )
        )
)
SELECT 
    DISTINCT h.o_orderkey,
    CONCAT('Order ', h.o_orderkey, ' by ', ss.s_name) AS order_supplier,
    CASE 
        WHEN hr.price_rank IS NOT NULL THEN CONCAT('Highly Rated Part: ', hp.p_name, ' at ', hp.p_retailprice)
        ELSE 'No Highly Rated Part'
    END AS part_info
FROM 
    HighValueOrders h
LEFT JOIN 
    RankedSuppliers ss ON ss.acct_rank = 1
LEFT JOIN 
    HighlyRatedParts hp ON hp.p_partkey IN (
        SELECT l.l_partkey
        FROM lineitem l
        WHERE l.l_orderkey = h.o_orderkey
        GROUP BY l.l_partkey
        HAVING SUM(l.l_quantity) > 10
    )
WHERE 
    (ss.s_name IS NOT NULL OR hp.p_partkey IS NULL)
ORDER BY 
    h.o_orderkey DESC, ss.s_name NULLS LAST;
