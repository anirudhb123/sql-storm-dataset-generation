WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) as ranking
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey, o.o_totalprice
    HAVING 
        net_revenue > 100000
) 
SELECT 
    p.p_name,
    ps.ps_availqty,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_returned,
    COALESCE(SUM(l.l_quantity), 0) AS total_ordered,
    (SELECT MAX(c.c_acctbal) 
     FROM customer c 
     WHERE c.c_nationkey IN (SELECT DISTINCT n.n_regionkey
                             FROM nation n 
                             WHERE n.n_nationkey = 
                                 (SELECT n2.n_nationkey 
                                  FROM nation n2 
                                  JOIN customer c2 ON n2.n_nationkey = c2.c_nationkey 
                                  WHERE c2.c_acctbal > 1000 LIMIT 1)
                            )
    ) AS max_account_balance
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.ranking < 5
FULL OUTER JOIN 
    HighValueOrders hvo ON ps.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = hvo.o_orderkey AND l.l_linenumber % 2 = 0
    )
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND p.p_retailprice IS NOT NULL
GROUP BY 
    p.p_name, ps.ps_availqty
HAVING 
    COUNT(DISTINCT rs.s_suppkey) > 0
ORDER BY 
    total_ordered DESC, total_returned ASC
LIMIT 10;
