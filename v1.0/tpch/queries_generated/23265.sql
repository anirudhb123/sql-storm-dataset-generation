WITH RECURSIVE OrderTree AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice + ot.o_totalprice, ot.level + 1
    FROM orders o
    JOIN OrderTree ot ON o.o_custkey = ot.o_custkey AND o.o_orderdate > ot.o_orderdate
    WHERE ot.level < 5
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(ot.o_totalprice) AS total_order_value,
    AVG(ot.o_totalprice) AS avg_order_value,
    STRING_AGG(DISTINCT p.p_name, ', ') FILTER (WHERE p.p_size > 10) AS large_parts,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ot.o_totalprice) DESC) AS rank_by_value
FROM 
    OrderTree ot
JOIN customer c ON ot.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN lineitem li ON ot.o_orderkey = li.l_orderkey
FULL OUTER JOIN partsupp ps ON li.l_partkey = ps.ps_partkey AND li.l_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE 
    (p.p_retailprice IS NOT NULL AND p.p_retailprice > 0.00)
    OR EXISTS (SELECT 1 FROM supplier s WHERE s.s_suppkey = ps.ps_suppkey AND s.s_acctbal < 0)
GROUP BY 
    n.n_name
HAVING 
    COUNT(pi.p_partkey) > 2 AND AVG(ot.o_totalprice) <= (SELECT AVG(o_totalprice) FROM orders WHERE o_orderstatus = 'O')
ORDER BY 
    total_order_value DESC,
    nation_name ASC;
