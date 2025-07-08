WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > ch.c_acctbal
)

SELECT
    n.n_name AS nation_name,
    SUM(CASE 
            WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE 0 
        END) AS completed_sales,
    COUNT(DISTINCT CASE 
                    WHEN l.l_returnflag = 'R' THEN l.l_orderkey 
                   END) AS returned_orders,
    AVG(COALESCE(ps.ps_supplycost, 0)) AS avg_supplycost,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice) DESC) AS rank_in_nation
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
WHERE l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
  AND l.l_quantity > (SELECT AVG(l2.l_quantity) FROM lineitem l2 WHERE l2.l_orderkey = o.o_orderkey)
GROUP BY n.n_name
HAVING SUM(CASE WHEN l.l_discount > 0.1 THEN 1 ELSE 0 END) > 5
ORDER BY completed_sales DESC, n.n_name ASC
LIMIT 10;