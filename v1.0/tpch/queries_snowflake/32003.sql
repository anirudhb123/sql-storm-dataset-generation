
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, 1 AS level
    FROM customer c
    WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey <> ch.c_custkey
    WHERE c.c_acctbal < (SELECT AVG(c2.c_acctbal) FROM customer c2)
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= '1996-01-01'
)
SELECT 
    r.r_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS part_names,
    AVG(lo.l_extendedprice) AS avg_extended_price,
    MAX(lo.l_discount) AS max_discount
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem lo ON lo.l_partkey = p.p_partkey
JOIN CustomerHierarchy ch ON ch.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT lo.l_orderkey FROM lineitem lo))
WHERE lo.l_shipdate IS NOT NULL
AND (lo.l_returnflag IS NULL OR lo.l_returnflag <> 'R')
AND ch.level <= 3
GROUP BY r.r_name
HAVING SUM(ps.ps_availqty) > 1000 
ORDER BY r.r_name;
