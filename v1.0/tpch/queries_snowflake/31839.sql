
WITH RECURSIVE region_nation AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey 
    FROM nation n 
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'AFRICA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey
    FROM nation n 
    INNER JOIN region_nation rn ON n.n_regionkey = rn.n_nationkey
)

SELECT 
    p.p_partkey, 
    p.p_name, 
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_net_price,
    COALESCE(SUM(ps.ps_availqty), 0) AS total_available_quantity,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
FROM 
    part p 
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
WHERE 
    EXISTS (
        SELECT 1 
        FROM supplier s 
        WHERE s.s_suppkey = l.l_suppkey 
        AND s.s_acctbal > 10000
        AND s.s_nationkey IN (
            SELECT rn.n_nationkey 
            FROM region_nation rn
        )
    )
    AND (l.l_shipdate >= '1996-01-01' OR l.l_shipdate IS NULL)
GROUP BY 
    p.p_partkey, p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    avg_net_price DESC;
